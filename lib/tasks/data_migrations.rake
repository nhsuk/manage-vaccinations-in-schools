# frozen_string_literal: true

namespace :data_migrations do
  desc "Remove trailing dots from all parent emails"
  task remove_trailing_dots_from_parent_emails: :environment do
    parents = Parent.where.not(email: nil).select { it.email.ends_with?(".") }

    puts "#{parents.count} parents with trailing dots in their email addresses"

    parents.each do |parent|
      email = parent.email.delete_suffix(".")
      parent.update_column(:email, email)
    end
  end
end
