# frozen_string_literal: true

# Same cookie as before (so nobody is signed out by this change), now with an
# expiry: browsers no longer keep a sign-in around indefinitely. The server
# enforces the real limits too (ApplicationController::SESSION_MAX_AGE and
# SESSION_IDLE_TIMEOUT), since a cookie's expiry is up to the browser.
Rails.application.config.session_store :cookie_store, key: "_kbnf_session", expire_after: 14.days
