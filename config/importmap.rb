# frozen_string_literal: true

# JavaScript modules, loaded by the browser without a build step.
#
# jQuery, Bootstrap 5 and jQuery UI are not modules: they are plain scripts in
# vendor/javascript, loaded by the layout before these modules run, and the app
# code uses the global $ they set up.

pin "application"
pin "@rails/ujs", to: "rails-ujs.esm.js" # ships with Rails (actionview)
pin "chartkick", to: "chartkick.js"      # ships with the chartkick gem
pin "Chart.bundle", to: "Chart.bundle.js" # Chart.js, ships with the chartkick gem
pin_all_from "app/javascript/src", under: "src"
