# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccines
#
#  id         :bigint           not null, primary key
#  brand      :text
#  dose       :decimal(, )
#  gtin       :text
#  method     :integer
#  supplier   :text
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Vaccine < ApplicationRecord
  self.inheritance_column = :_type_disabled

  audited

  has_and_belongs_to_many :campaigns
  has_many :health_questions, dependent: :destroy
  has_many :batches

  validates :type, presence: true
  validates :brand, presence: true
  validates :method, presence: true

  enum :method, %i[injection nasal]

  delegate :first_health_question, to: :health_questions

  def contains_gelatine?
    type.downcase == "flu" && nasal?
  end
end
