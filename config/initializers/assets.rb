# frozen_string_literal: true

# The SCSS sources are compiled into app/assets/builds by dartsass-rails;
# do not also publish the raw .scss files.
Rails.application.config.assets.excluded_paths << Rails.root.join("app/assets/stylesheets")
