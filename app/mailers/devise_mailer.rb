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
end
