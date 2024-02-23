# Prompt for a username if either the support user is defined, or we are in
# production. In production, if no support user is defined then no access is
# available.

support_user_defined =
  Settings.support_username.present? && Settings.support_password.present?

if Rails.env.production? || support_user_defined
  GoodJob::Engine
    .middleware
    .use(Rack::Auth::Basic) do |username, password|
      if support_user_defined
        ActiveSupport::SecurityUtils.secure_compare(
          Settings.support_username,
          username
        ) &&
          ActiveSupport::SecurityUtils.secure_compare(
            Settings.support_password,
            password
          )
      end
    end
end
