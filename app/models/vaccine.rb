# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccines
#
#  id                  :bigint           not null, primary key
#  brand               :text             not null
#  dose                :decimal(, )      not null
#  gtin                :text
#  manufacturer        :text             not null
#  method              :integer          not null
#  snomed_product_code :string           not null
#  snomed_product_term :string           not null
#  type                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_vaccines_on_gtin                    (gtin) UNIQUE
#  index_vaccines_on_manufacturer_and_brand  (manufacturer,brand) UNIQUE
#  index_vaccines_on_snomed_product_code     (snomed_product_code) UNIQUE
#  index_vaccines_on_snomed_product_term     (snomed_product_term) UNIQUE
#
class Vaccine < ApplicationRecord
  self.inheritance_column = :_type_disabled

  audited

  has_and_belongs_to_many :campaigns
  has_many :health_questions, dependent: :destroy
  has_many :batches

  validates :brand, presence: true, uniqueness: { scope: :manufacturer }
  validates :dose, presence: true
  validates :gtin, uniqueness: true, allow_nil: true
  validates :manufacturer, presence: true
  validates :method, presence: true
  validates :snomed_product_code, presence: true, uniqueness: true
  validates :snomed_product_term, presence: true, uniqueness: true
  validates :type, presence: true

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

  def maximum_dose_sequence
    if type.downcase == "flu"
      1
    elsif type.downcase == "hpv"
      3
    else
      raise NotImplementedError,
            "Maximum dose sequence not implemented for #{type} vaccines."
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

  def snomed_procedure_code_and_term
    case type.downcase
    when "hpv"
      [
        "761841000",
        "Administration of vaccine product containing only Human papillomavirus antigen (procedure)"
      ]
    when "flu"
      ["822851000000102", "Seasonal influenza vaccination (procedure)"]
    else
      raise NotImplementedError,
            "SNOMED procedure code and term not implemented for #{type} vaccines."
    end
  end
end
