# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccines
#
#  id                  :bigint           not null, primary key
#  brand               :text             not null
#  contains_gelatine   :boolean          not null
#  discontinued        :boolean          default(FALSE), not null
#  disease_types       :enum             default([]), not null, is an Array
#  dose_volume_ml      :decimal(, )      not null
#  manufacturer        :text             not null
#  method              :integer          not null
#  nivs_name           :string
#  programme_type      :enum             not null
#  side_effects        :integer          default([]), not null, is an Array
#  snomed_product_code :string           not null
#  snomed_product_term :string           not null
#  upload_name         :text             not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_vaccines_on_manufacturer_and_brand  (manufacturer,brand) UNIQUE
#  index_vaccines_on_programme_type          (programme_type)
#  index_vaccines_on_snomed_product_code     (snomed_product_code) UNIQUE
#  index_vaccines_on_snomed_product_term     (snomed_product_term) UNIQUE
#  index_vaccines_on_upload_name             (upload_name) UNIQUE
#
class Vaccine < ApplicationRecord
  include BelongsToProgramme
  include HasSideEffects

  audited
  has_associated_audits

  has_many :health_questions, dependent: :destroy
  has_many :batches

  validates :brand, presence: true, uniqueness: { scope: :manufacturer }
  validates :dose_volume_ml, presence: true
  validates :manufacturer, presence: true
  validates :snomed_product_code, presence: true, uniqueness: true
  validates :snomed_product_term, presence: true, uniqueness: true

  METHOD_INJECTION = "injection"
  METHOD_NASAL = "nasal"

  enum :method, { METHOD_INJECTION => 0, METHOD_NASAL => 1 }, validate: true

  scope :active, -> { where(discontinued: false) }
  scope :discontinued, -> { where(discontinued: true) }

  scope :with_disease_types,
        ->(disease_types) do
          return all if disease_types.blank?

          where(
            "disease_types <@ ARRAY[?]::disease_type[]",
            disease_types
          ).where("disease_types @> ARRAY[?]::disease_type[]", disease_types)
        end

  delegate :first_health_question, to: :health_questions

  delegate :fhir_codeable_concept,
           :fhir_manufacturer_reference,
           :fhir_procedure_coding,
           to: :fhir_mapper

  def active? = !discontinued

  AVAILABLE_DELIVERY_SITES = {
    "injection" => %w[
      left_arm_upper_position
      left_arm_lower_position
      right_arm_upper_position
      right_arm_lower_position
      left_thigh
      right_thigh
      left_buttock
      right_buttock
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

  SNOMED_PROCEDURE = {
    "flu" => {
      "injection" => [
        {
          code: "985151000000100",
          term:
            "Administration of first inactivated seasonal influenza vaccination"
        },
        {
          code: "985171000000109",
          term:
            "Administration of second inactivated seasonal influenza vaccination"
        }
      ],
      "nasal" => [
        {
          code: "884861000000100",
          term:
            "Administration of first intranasal seasonal influenza vaccination"
        },
        {
          code: "884881000000109",
          term:
            "Administration of second intranasal seasonal influenza vaccination"
        }
      ]
    },
    "hpv" => {
      "injection" => {
        code: "761841000",
        term:
          "Administration of vaccine product containing only Human " \
            "papillomavirus antigen"
      }
    },
    "menacwy" => {
      "injection" => {
        code: "871874000",
        term:
          "Administration of vaccine product containing only Neisseria " \
            "meningitidis serogroup A, C, W135 and Y antigens"
      }
    },
    "mmr" => {
      "injection" => {
        code: "38598009",
        term:
          "Administration of vaccine product containing only Measles " \
            "morbillivirus and Mumps orthorubulavirus and Rubella virus " \
            "antigens"
      }
    },
    "mmrv" => {
      "injection" => {
        code: "432636005",
        term:
          "Administration of vaccine product containing only Human " \
            "alphaherpesvirus 3 and Measles morbillivirus and Mumps " \
            "orthorubulavirus and Rubella virus antigens"
      }
    },
    "td_ipv" => {
      "injection" => {
        code: "414619005",
        term:
          "Administration of vaccine product containing only Clostridium " \
            "tetani and low dose Corynebacterium diphtheriae and inactivated " \
            "Human poliovirus antigens"
      }
    }
  }.freeze

  def snomed_procedure(dose_sequence: nil)
    procedures =
      SNOMED_PROCEDURE.fetch(programme.variant_type || programme.type).fetch(
        method
      )

    procedures.is_a?(Array) ? procedures[(dose_sequence || 1) - 1] : procedures
  end

  def snomed_procedure_code(dose_sequence:)
    snomed_procedure(dose_sequence:).fetch(:code)
  end

  def snomed_procedure_term(dose_sequence: nil)
    snomed_procedure(dose_sequence:).fetch(:term)
  end

  private

  def fhir_mapper
    @fhir_mapper ||= FHIRMapper::Vaccine.new(self)
  end
end
