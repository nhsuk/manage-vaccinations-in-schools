# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccines
#
#  id                  :bigint           not null, primary key
#  brand               :text             not null
#  discontinued        :boolean          default(FALSE), not null
#  dose_volume_ml      :decimal(, )      not null
#  manufacturer        :text             not null
#  method              :integer          not null
#  nivs_name           :text             not null
#  side_effects        :integer          default([]), not null, is an Array
#  snomed_product_code :string           not null
#  snomed_product_term :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  programme_id        :bigint           not null
#
# Indexes
#
#  index_vaccines_on_manufacturer_and_brand  (manufacturer,brand) UNIQUE
#  index_vaccines_on_nivs_name               (nivs_name) UNIQUE
#  index_vaccines_on_programme_id            (programme_id)
#  index_vaccines_on_snomed_product_code     (snomed_product_code) UNIQUE
#  index_vaccines_on_snomed_product_term     (snomed_product_term) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (programme_id => programmes.id)
#
class Vaccine < ApplicationRecord
  include HasSideEffects

  audited associated_with: :programme
  has_associated_audits

  belongs_to :programme

  has_many :health_questions, dependent: :destroy
  has_many :batches

  validates :brand, presence: true, uniqueness: { scope: :manufacturer }
  validates :dose_volume_ml, presence: true
  validates :manufacturer, presence: true
  validates :snomed_product_code, presence: true, uniqueness: true
  validates :snomed_product_term, presence: true, uniqueness: true

  enum :method, { injection: 0, nasal: 1 }, validate: true

  scope :active, -> { where(discontinued: false) }
  scope :discontinued, -> { where(discontinued: true) }

  delegate :first_health_question, to: :health_questions
  delegate :fhir_codeable_concept,
           :fhir_manufacturer_reference,
           :fhir_procedure_coding,
           to: :fhir_mapper

  def active? = !discontinued

  def contains_gelatine? = programme.flu? && nasal?

  AVAILABLE_DELIVERY_SITES = {
    "injection" => %w[
      left_arm_upper_position
      left_arm_lower_position
      right_arm_upper_position
      right_arm_lower_position
      left_thigh
      right_thigh
    ],
    "nasal" => %w[nose]
  }.freeze

  def available_delivery_sites
    AVAILABLE_DELIVERY_SITES.fetch(method)
  end

  AVAILABLE_DELIVERY_METHODS = {
    "nasal" => %w[nasal_spray].freeze,
    "injection" => %w[intramuscular subcutaneous].freeze
  }.freeze

  def available_delivery_methods
    AVAILABLE_DELIVERY_METHODS.fetch(method)
  end

  def self.delivery_method_to_vaccine_method(delivery_method)
    return nil if delivery_method.nil?

    suitable_delivery_methods =
      AVAILABLE_DELIVERY_METHODS.select do |_key, value|
        delivery_method.in?(value)
      end

    suitable_delivery_methods.keys.first
  end

  SNOMED_PROCEDURE_CODES = {
    "flu" => "822851000000102",
    "hpv" => "761841000",
    "menacwy" => "871874000",
    "td_ipv" => "866186002"
  }.freeze

  def snomed_procedure_code
    SNOMED_PROCEDURE_CODES.fetch(programme.type)
  end

  SNOMED_PROCEDURE_TERMS = {
    "flu" => "Seasonal influenza vaccination (procedure)",
    "hpv" =>
      "Administration of vaccine product containing only Human " \
        "papillomavirus antigen (procedure)",
    "menacwy" =>
      "Administration of vaccine product containing only Neisseria " \
        "meningitidis serogroup A, C, W135 and Y antigens (procedure)",
    "td_ipv" =>
      "Administration of vaccine product containing only Clostridium " \
        "tetani and Corynebacterium diphtheriae and Human poliovirus " \
        "antigens (procedure)"
  }.freeze

  def snomed_procedure_term
    SNOMED_PROCEDURE_TERMS.fetch(programme.type)
  end

  private

  def fhir_mapper
    @fhir_mapper ||= FHIRMapper::Vaccine.new(self)
  end
end
