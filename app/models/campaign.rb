# == Schema Information
#
# Table name: campaigns
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Campaign < ApplicationRecord
  audited

  has_and_belongs_to_many :vaccines
  has_many :batches, through: :vaccines
  has_many :sessions, dependent: :destroy
  has_many :triage, dependent: :destroy
  has_many :consents, dependent: :destroy

  validates :name, presence: true
end
