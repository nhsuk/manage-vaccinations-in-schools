# == Schema Information
#
# Table name: registrations
#
#  id                               :bigint           not null, primary key
#  address_line_1                   :string
#  address_line_2                   :string
#  address_postcode                 :string
#  address_town                     :string
#  common_name                      :string
#  consent_response_confirmed       :boolean
#  data_processing_agreed           :boolean
#  date_of_birth                    :date
#  first_name                       :string
#  last_name                        :string
#  nhs_number                       :string
#  parent_email                     :string
#  parent_name                      :string
#  parent_phone                     :string
#  parent_relationship              :integer
#  parent_relationship_other        :string
#  terms_and_conditions_agreed      :boolean
#  use_common_name                  :boolean
#  user_research_observation_agreed :boolean
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  location_id                      :bigint           not null
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
  has_one :patient

  enum :parent_relationship, %w[mother father guardian other], prefix: true

  encrypts :address_line_1,
           :address_line_2,
           :address_postcode,
           :address_town,
           :common_name,
           :first_name,
           :last_name,
           :nhs_number,
           :parent_email,
           :parent_name,
           :parent_phone,
           :parent_relationship_other

  validates :address_line_1, presence: true, length: { maximum: 300 }
  validates :address_town, presence: true, length: { maximum: 300 }
  validates :address_postcode, presence: true, postcode: true
  validates :date_of_birth,
            presence: true,
            comparison: {
              less_than: Time.zone.today,
              greater_than_or_equal_to: 22.years.ago.to_date,
              less_than_or_equal_to: 3.years.ago.to_date
            }
  validates :first_name, presence: true, length: { maximum: 300 }
  validates :last_name, presence: true, length: { maximum: 300 }
  validates :common_name,
            presence: true,
            length: {
              maximum: 300
            },
            if: :use_common_name?
  validates :nhs_number,
            uniqueness: true,
            format: {
              with: /\A(?:\d\s*){10}\z/
            },
            if: :nhs_number?
  validates :parent_email, presence: true, email: true, length: { maximum: 300 }
  validates :parent_name, presence: true, length: { maximum: 300 }
  validates :parent_phone,
            presence: true,
            phone: true,
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
  validates :use_common_name,
            inclusion: {
              in: [true, false]
            },
            length: {
              maximum: 300
            }
  validates :conditions_for_taking_part_met, acceptance: true

  delegate :name, to: :location, prefix: true

  def conditions_for_taking_part_met
    conditions = [
      consent_response_confirmed?,
      data_processing_agreed?,
      terms_and_conditions_agreed?,
      user_research_observation_agreed?
    ].compact

    conditions.all?
  end

  def formatted_parent_relationship
    if parent_relationship_other?
      parent_relationship_other
    else
      parent_relationship.capitalize
    end
  end
end
