# == Schema Information
#
# Table name: registrations
#
#  id                        :bigint           not null, primary key
#  parent_email              :string           not null
#  parent_name               :string           not null
#  parent_phone              :string
#  parent_relationship       :integer          not null
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
end
