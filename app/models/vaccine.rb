# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccines
#
#  id                  :bigint           not null, primary key
#  brand               :text             not null
#  discontinued        :boolean          default(FALSE), not null
#  dose                :decimal(, )      not null
#  gtin                :text
#  manufacturer        :text             not null
#  method              :integer          not null
#  nivs_name           :text             not null
#  snomed_product_code :string           not null
#  snomed_product_term :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  programme_id        :bigint           not null
#
# Indexes
#
#  index_vaccines_on_gtin                    (gtin) UNIQUE
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
  self.inheritance_column = nil

  audited

  belongs_to :programme

  has_and_belongs_to_many :programmes
  has_many :health_questions, dependent: :destroy
  has_many :batches, -> { order(:name) }

  validates :brand, presence: true, uniqueness: { scope: :manufacturer }
  validates :dose, presence: true
  validates :gtin, uniqueness: true, allow_nil: true
  validates :manufacturer, presence: true
  validates :snomed_product_code, presence: true, uniqueness: true
  validates :snomed_product_term, presence: true, uniqueness: true

  enum :method, %i[injection nasal], validate: true

  scope :active, -> { where(discontinued: false) }

  delegate :first_health_question, to: :health_questions

  def contains_gelatine?
    programme.flu? && nasal?
  end

  def common_delivery_sites
    if programme.hpv?
      %w[left_arm_upper_position right_arm_upper_position]
    else
      raise NotImplementedError,
            "Common delivery sites not implemented for #{type} vaccines."
    end
  end

  def maximum_dose_sequence
    { "flu" => 1, "hpv" => 3 }.fetch(programme.type)
  end

  def seasonal?
    programme.flu?
  end

  AVAILABLE_DELIVERY_SITES_BY_METHOD = {
    "injection" =>
      VaccinationRecord.delivery_sites.keys -
        %w[left_buttock right_buttock nose],
    "nasal" => %w[nose]
  }.freeze

  def available_delivery_sites
    AVAILABLE_DELIVERY_SITES_BY_METHOD.fetch(method)
  end

  AVAILABLE_DELIVERY_METHODS_BY_TYPE = {
    "hpv" => %w[intramuscular subcutaneous],
    "flu" => %w[nasal_spray]
  }.freeze

  def available_delivery_methods
    AVAILABLE_DELIVERY_METHODS_BY_TYPE.fetch(programme.type)
  end

  SNOMED_PROCEDURE_CODE_AND_TERM_BY_TYPE = {
    "hpv" => [
      "761841000",
      "Administration of vaccine product containing only Human papillomavirus antigen (procedure)"
    ],
    "flu" => ["822851000000102", "Seasonal influenza vaccination (procedure)"]
  }.freeze

  def snomed_procedure_code_and_term
    SNOMED_PROCEDURE_CODE_AND_TERM_BY_TYPE.fetch(programme.type)
  end
end
