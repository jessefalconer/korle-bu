# frozen_string_literal: true

module RequestHelpers
  def sign_in(user, password: "1234567890")
    post login_path, params: { email: user.email, password: password }
  end
end
