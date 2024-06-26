# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  def reset_password_instructions(record, token, _opts = {})
    template_mail(
      "79dc5ef9-ea93-4f00-8295-05bc3f814979",
      to: record.email,
      personalisation: {
        name: record.full_name,
        password_reset_link:
          edit_user_password_url(record, reset_password_token: token)
      }
    )
  end

  def unlock_instructions(record, token, _opts = {})
    template_mail(
      "4761dd5c-33b0-4594-9940-db4ed9b491c2",
      to: record.email,
      personalisation: {
        name: record.full_name,
        unlock_link: user_unlock_url(unlock_token: token)
      }
    )
  end
end
