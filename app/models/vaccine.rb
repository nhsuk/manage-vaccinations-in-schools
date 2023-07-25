# == Schema Information
#
# Table name: vaccines
#
#  id         :bigint           not null, primary key
#  brand      :text
#  method     :integer
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_vaccines_on_type  (type) UNIQUE
#
class Vaccine < ApplicationRecord
  self.inheritance_column = :_type_disabled

  has_and_belongs_to_many :campaigns
  has_many :health_questions, dependent: :destroy
  has_many :batches

  validates :type, presence: true
  validates :brand, presence: true
  validates :method, presence: true

  enum :method, %i[injection nasal]
end
