# == Schema Information
#
# Table name: vaccines
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_vaccines_on_name  (name) UNIQUE
#
class Vaccine < ApplicationRecord
  has_many :campaigns, dependent: :destroy
  has_many :health_questions, dependent: :destroy

  validates :name, presence: true
end
