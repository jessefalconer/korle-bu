# Production server

How the production server for inventory.kbnf.org is built and operated.

- **OS:** Ubuntu 24.04 LTS, automatic security updates and reboots (11:00 UTC)
- **App:** Ruby (rbenv) + Puma as a systemd user service of `deploy`, behind nginx
- **Database:** PostgreSQL 18, Unix socket only, `peer` authentication, no passwords
- **Access:** SSH keys only. `kbnfadmin` has sudo (with a password); `deploy` has none.
  Only ports 22, 80 and 443 are open.
- **Secrets:** `config/credentials/production.yml.enc` (committed, encrypted). Its key,
  `config/credentials/production.key`, is never committed: keep it in a password
  manager and on the server in `~/korle-bu/shared/config/credentials/`.

`HOST` below is `inventory.kbnf.org`, or a new server's IP address before DNS
points at it (pass it to Capistrano as `SERVER_HOST=...`).

## Building a new server

1. Create an Ubuntu 24.04 droplet with your SSH key (no password), and a cloud
   firewall allowing inbound 22, 80 and 443 only.
2. Run the setup script. It asks once for a password for `kbnfadmin` (used for sudo only):

   ```bash
   scp config/server/provision.sh root@HOST:
   ssh -t root@HOST 'bash provision.sh'
   ```

3. **In a new terminal, check `ssh kbnfadmin@HOST` works** before closing the root
   session: root login is disabled from then on.
4. Log in once as deploy so your machine records the server's host key, and upload
   the credentials key:

   ```bash
   ssh deploy@HOST exit
   scp config/credentials/production.key deploy@HOST:korle-bu/shared/config/credentials/
   ```

5. Load data (from a `pg_dump -Fc` backup), install the Puma service and deploy:

   ```bash
   scp backup.dump deploy@HOST:
   ssh deploy@HOST 'pg_restore --no-owner --no-acl -d kbnf_production backup.dump'
   SERVER_HOST=HOST bundle exec cap production puma:install
   SERVER_HOST=HOST bundle exec cap production deploy
   ```

6. Point the `inventory` DNS record at the server, then get the HTTPS certificate
   (certbot asks for an email and for you to accept Let's Encrypt's terms):

   ```bash
   ssh -t kbnfadmin@inventory.kbnf.org 'sudo certbot --nginx -d inventory.kbnf.org --redirect'
   ```

   Renewal is automatic. Check with `sudo certbot renew --dry-run`.

## Day-to-day

| Task | Command |
|---|---|
| Deploy `master` | `bundle exec cap production deploy` |
| Deploy a branch | `BRANCH=my-branch bundle exec cap production deploy` |
| Restart / status | `bundle exec cap production puma:restart` / `puma:status` |
| App logs | `ssh deploy@inventory.kbnf.org 'journalctl --user -u korle-bu_puma_production -n 200'` |
| Rails console | `ssh -t deploy@inventory.kbnf.org 'cd korle-bu/current && RAILS_ENV=production ~/.rbenv/bin/rbenv exec bundle exec rails console'` |
| Database backup | `ssh deploy@inventory.kbnf.org 'pg_dump -Fc -f ~/backup.dump kbnf_production'` |
| Edit secrets | `bin/rails credentials:edit --environment production`, then deploy |
