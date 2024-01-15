# == Schema Information
#
# Table name: registrations
#
#  id                        :bigint           not null, primary key
#  parent_email              :string
#  parent_name               :string
#  parent_phone              :string
#  parent_relationship       :integer
#  parent_relationship_other :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  location_id               :bigint           not null
#
# Indexes
#
#  index_registrations_on_location_id  (location_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#
class Registration < ApplicationRecord
  belongs_to :location

  enum :parent_relationship, %w[mother father guardian other], prefix: true

  validates :parent_name, presence: true, length: { maximum: 300 }
  validates :parent_email, presence: true, email: true, length: { maximum: 300 }
  validates :parent_phone,
            presence: true,
            phone_number: true,
            length: {
              maximum: 300
            },
            if: :parent_phone?
  validates :parent_relationship, presence: true
  validates :parent_relationship_other,
            presence: true,
            length: {
              maximum: 300
            },
            if: :parent_relationship_other?
end
