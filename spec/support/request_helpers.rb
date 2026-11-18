# frozen_string_literal: true

module RequestHelpers
  def sign_in(user, password: "1234567890")
    post login_path, params: { email: user.email, password: password }
  end

  # Lets full-page specs render without compiled webpacker assets.
  def skip_webpacker_assets
    allow_any_instance_of(ActionView::Base).to receive(:javascript_pack_tag).and_return("")
  end
end
