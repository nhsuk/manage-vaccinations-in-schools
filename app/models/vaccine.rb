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

  def common_delivery_sites
    if type.downcase == "hpv"
      %w[left_arm_upper_position right_arm_upper_position]
    else
      raise NotImplementedError,
            "Common delivery sites not implemented for #{type} vaccines."
    end
  end

  def available_delivery_sites
    if injection?
      VaccinationRecord.delivery_sites.keys -
        %w[left_buttock right_buttock nose]
    elsif nasal?
      %w[nose]
    else
      raise NotImplementedError,
            "Available delivery sites not implemented for #{method} vaccine."
    end
  end

  def available_delivery_methods
    if type.downcase == "hpv"
      %w[intramuscular subcutaneous]
    elsif type.downcase == "flu"
      %w[nasal_spray]
    else
      raise NotImplementedError,
            "Available delivery methods not implemented for #{type} vaccines."
    end
  end
end
