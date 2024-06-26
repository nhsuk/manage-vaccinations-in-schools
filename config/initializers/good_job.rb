# frozen_string_literal: true

GoodJob::Engine
  .middleware
  .use(Rack::Auth::Basic) do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(
      Settings.support_username,
      username
    ) &&
      ActiveSupport::SecurityUtils.secure_compare(
        Settings.support_password,
        password
      )
  end
