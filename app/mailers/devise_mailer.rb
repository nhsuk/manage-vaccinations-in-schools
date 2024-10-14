# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
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
