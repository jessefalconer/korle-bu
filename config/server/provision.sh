#!/usr/bin/env bash
#
# One-time setup of a fresh Ubuntu 24.04 droplet for korle-bu (inventory.kbnf.org).
#
#   scp config/server/provision.sh root@NEW_IP:
#   ssh -t root@NEW_IP 'bash provision.sh'
#
# Safe to re-run: each step checks whether it is already done.
#
# What it sets up:
#   - users: "admin" (sudo, with a password you choose) and "deploy" (runs the
#     app, NO sudo). Both log in with the SSH key(s) the droplet was created with.
#   - SSH: keys only, no root login, no passwords, no agent forwarding
#   - firewall: only 22, 80, 443; fail2ban for SSH
#   - automatic security updates with automatic reboots
#   - 2 GB swap, auto-reboot after a kernel panic
#   - PostgreSQL 18 (from the PostgreSQL project's apt repo), socket-only, peer auth
#   - nginx in front of Puma, certbot for HTTPS
#   - Ruby (rbenv) for the deploy user, Puma as a user service

set -euo pipefail

RUBY_VERSION="${RUBY_VERSION:-4.0.10}"
PG_VERSION=18
APP=korle-bu
DOMAIN=inventory.kbnf.org
DB=kbnf_production
ADMIN=admin
DEPLOY=deploy

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

[ "$(id -u)" = 0 ] || die "Run this as root."
. /etc/os-release
[ "${VERSION_ID:-}" = "24.04" ] || die "Expected Ubuntu 24.04, found ${PRETTY_NAME:-unknown}."
[ -s /root/.ssh/authorized_keys ] || die "/root/.ssh/authorized_keys is empty; create the droplet with your SSH key."

export DEBIAN_FRONTEND=noninteractive

log "Updating the system"
apt-get update -y
apt-get -y -o Dpkg::Options::=--force-confold full-upgrade

log "Installing packages"
apt-get install -y \
  ufw fail2ban python3-systemd unattended-upgrades \
  nginx certbot python3-certbot-nginx \
  git curl ca-certificates postgresql-common \
  autoconf patch build-essential rustc pkg-config \
  libssl-dev libyaml-dev libreadline-dev zlib1g-dev libgmp-dev libncurses-dev \
  libffi-dev libgdbm-dev libdb-dev uuid-dev libpq-dev

log "Swap and kernel settings"
if ! swapon --show | grep -q '^/swapfile'; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
fi
grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
cat > /etc/sysctl.d/99-kbnf.conf <<'EOF'
# Prefer RAM, use swap only under pressure
vm.swappiness = 10
# Reboot 10 s after a kernel panic instead of hanging until someone notices
kernel.panic = 10
kernel.panic_on_oops = 1
EOF
sysctl --system > /dev/null

log "Keeping system logs (journal) bounded"
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/kbnf.conf <<'EOF'
[Journal]
Storage=persistent
SystemMaxUse=500M
EOF
systemctl restart systemd-journald

log "Users: $ADMIN (sudo) and $DEPLOY (no sudo)"
for u in "$ADMIN" "$DEPLOY"; do
  id "$u" &> /dev/null || adduser --disabled-password --gecos "" "$u"
  install -d -m 700 -o "$u" -g "$u" "/home/$u/.ssh"
  install -m 600 -o "$u" -g "$u" /root/.ssh/authorized_keys "/home/$u/.ssh/authorized_keys"
done
usermod -aG sudo "$ADMIN"
gpasswd -d "$DEPLOY" sudo &> /dev/null || true
# nginx (www-data) must be able to reach /home/deploy/korle-bu/current/public
chmod 711 "/home/$DEPLOY"
# Let the deploy user's Puma service run without anyone logged in
loginctl enable-linger "$DEPLOY"

if ! passwd -S "$ADMIN" | grep -q ' P '; then
  echo
  echo "Choose a strong password for '$ADMIN'. It is only used for sudo (SSH stays key-only)."
  echo "Store it in your password manager."
  passwd "$ADMIN"
fi

log "Locking down SSH"
cat > /etc/ssh/sshd_config.d/00-kbnf-hardening.conf <<EOF
# Keys only, no root, only these two accounts
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
AllowUsers $ADMIN $DEPLOY
AllowAgentForwarding no
X11Forwarding no
MaxAuthTries 3
EOF
sshd -t
systemctl restart ssh
passwd -l root > /dev/null

log "Firewall (22, 80, 443 only) and fail2ban"
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable
cat > /etc/fail2ban/jail.d/sshd.local <<'EOF'
[sshd]
enabled = true
backend = systemd
maxretry = 5
bantime = 1h
EOF
systemctl enable --now fail2ban
systemctl restart fail2ban

log "PostgreSQL $PG_VERSION (socket only, peer authentication)"
if [ ! -f /etc/apt/sources.list.d/pgdg.sources ] && [ ! -f /etc/apt/sources.list.d/pgdg.list ]; then
  /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y
fi
apt-get install -y "postgresql-$PG_VERSION"
cat > "/etc/postgresql/$PG_VERSION/main/conf.d/kbnf.conf" <<'EOF'
# No network listener at all: the app connects over the local Unix socket
listen_addresses = ''
password_encryption = 'scram-sha-256'
EOF
systemctl restart postgresql
# Role named after the Linux user, so "peer" auth lets deploy in with no password.
# Not a superuser; it only owns the app's database.
sudo -u postgres psql -v ON_ERROR_STOP=1 -q <<EOF
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$DEPLOY') THEN
    CREATE ROLE $DEPLOY LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
  END IF;
END
\$\$;
EOF
sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = '$DB'" | grep -q 1 \
  || sudo -u postgres createdb -O "$DEPLOY" "$DB"

log "Automatic security updates (including PostgreSQL), with reboots at 11:00 UTC (3 am Pacific)"
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
cat > /etc/apt/apt.conf.d/52kbnf-unattended-upgrades <<'EOF'
Unattended-Upgrade::Origins-Pattern {
  "origin=apt.postgresql.org,archive=${distro_codename}-pgdg";
};
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "11:00";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF

log "nginx site for $DOMAIN"
cat > "/etc/nginx/sites-available/$APP" <<EOF
upstream ${APP}_puma {
  server 127.0.0.1:3000 fail_timeout=0;
}

server {
  listen 80;
  listen [::]:80;
  server_name $DOMAIN;

  root /home/$DEPLOY/$APP/current/public;
  client_max_body_size 10m;

  # Digest-stamped assets never change: cache forever, serve pre-gzipped copies
  location ^~ /assets/ {
    gzip_static on;
    expires max;
    add_header Cache-Control "public, immutable";
    try_files \$uri =404;
  }

  # Anything else that exists in public/ is served directly, the rest goes to Rails
  location / {
    try_files \$uri @app;
  }

  location @app {
    proxy_pass http://${APP}_puma;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_redirect off;
  }

  error_page 500 502 503 504 /500.html;
}
EOF
ln -sf "/etc/nginx/sites-available/$APP" "/etc/nginx/sites-enabled/$APP"
rm -f /etc/nginx/sites-enabled/default
sed -i 's/^\s*#\?\s*server_tokens .*/\tserver_tokens off;/' /etc/nginx/nginx.conf
nginx -t
systemctl restart nginx

log "Ruby $RUBY_VERSION for $DEPLOY (rbenv; this takes 10-15 minutes)"
sudo -u "$DEPLOY" -H RUBY_VERSION="$RUBY_VERSION" bash <<'EOF'
set -euo pipefail
[ -d ~/.rbenv ] || git clone -q --depth 1 https://github.com/rbenv/rbenv.git ~/.rbenv
if [ -d ~/.rbenv/plugins/ruby-build ]; then
  git -C ~/.rbenv/plugins/ruby-build pull -q
else
  git clone -q --depth 1 https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi
grep -q 'rbenv init' ~/.bashrc || echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> ~/.bashrc
~/.rbenv/bin/rbenv install -s "$RUBY_VERSION"
~/.rbenv/bin/rbenv global "$RUBY_VERSION"
~/.rbenv/bin/rbenv exec gem install bundler --no-document -q
EOF

log "App folders for $DEPLOY"
# The repo is public, so the server clones it over HTTPS and holds no GitHub key.
sudo -u "$DEPLOY" -H mkdir -p "/home/$DEPLOY/$APP/shared/config/credentials"

log "Done"
cat <<EOF

Next steps (see config/server/README.md):

  1. BEFORE closing this window, open a new terminal and check you can log in:
       ssh $ADMIN@$(curl -s -m 3 http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address 2> /dev/null || echo NEW_IP)
     Root login is now disabled, so keep this session open until that works.

  2. From your Mac, upload the production credentials key:
       scp config/credentials/production.key $DEPLOY@NEW_IP:$APP/shared/config/credentials/

EOF
