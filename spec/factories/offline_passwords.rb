# frozen_string_literal: true

# == Schema Information
#
# Table name: offline_passwords
#
#  id         :bigint           not null, primary key
#  password   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :offline_password do
    password { "MyString" }
  end
end
