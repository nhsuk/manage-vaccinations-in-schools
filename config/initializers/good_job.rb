# frozen_string_literal: true

GoodJob::Engine
  .middleware
  .use(Rack::Auth::Basic) do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(
      Rails.application.credentials.support_username,
      username
    ) &&
      ActiveSupport::SecurityUtils.secure_compare(
        Rails.application.credentials.support_password,
        password
      )
  end
