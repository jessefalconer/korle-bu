# frozen_string_literal: true

# The SCSS sources are compiled into app/assets/builds by dartsass-rails;
# do not also publish the raw .scss files.
Rails.application.config.assets.excluded_paths << Rails.root.join("app/assets/stylesheets")

# Bootstrap's SCSS source is compiled through application.scss (see
# _bootstrap-custom.scss); it doesn't need publishing on its own either.
Rails.application.config.assets.excluded_paths << Rails.root.join("vendor/assets/stylesheets/bootstrap")

# Bootstrap 5.3's SCSS still uses @import and global Sass functions, which Dart Sass
# warns about on every build. --quiet-deps hides warnings from files on the load
# path (Bootstrap); the import deprecation also covers our own application.scss.
Rails.application.config.dartsass.build_options |= ["--quiet-deps", "--silence-deprecation=import"]
