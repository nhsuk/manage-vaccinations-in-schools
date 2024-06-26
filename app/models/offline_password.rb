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
class OfflinePassword < ApplicationRecord
  validates :password,
            presence: true,
            confirmation: true,
            length: {
              minimum: 12,
              maximum: 300
            }
end
