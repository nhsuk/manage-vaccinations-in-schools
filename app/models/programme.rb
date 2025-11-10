# frozen_string_literal: true

# == Schema Information
#
# Table name: programmes
#
#  id         :bigint           not null, primary key
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_programmes_on_type  (type) UNIQUE
#
class Programme < ApplicationRecord
  include GelatineVaccinesConcern

  self.inheritance_column = nil

  TYPES_SUPPORTING_DELEGATION = %w[flu].freeze

  enum :type,
       {
         flu: "flu",
         hpv: "hpv",
         menacwy: "menacwy",
         mmr: "mmr",
         td_ipv: "td_ipv"
       },
       validate: true

  delegate :fhir_target_disease_coding, to: :fhir_mapper

  def to_param = type

  def name = human_enum_name(:type)

  def name_in_sentence = flu? ? name.downcase : name

  def group
    if flu?
      :flu
    elsif hpv?
      :hpv
    elsif doubles?
      :doubles
    elsif mmr?
      :mmr
    else
      raise UnsupportedProgramme, self
    end
  end

  def doubles? = menacwy? || td_ipv?

  def seasonal? = flu?

  def catch_up_only? = mmr?

  def supports_delegation? = flu?

  def can_save_to_todays_batch? = !mmr?

  def triage_on_vaccination_history? = menacwy? || td_ipv?

  DEFAULT_YEAR_GROUPS_BY_TYPE = {
    "flu" => (0..11).to_a,
    "hpv" => (8..11).to_a,
    "menacwy" => (9..11).to_a,
    "mmr" => (0..11).to_a,
    "td_ipv" => (9..11).to_a
  }.freeze

  def default_year_groups
    DEFAULT_YEAR_GROUPS_BY_TYPE.fetch(type)
  end

  def vaccines
    @vaccines ||= Vaccine.where_programme(self)
  end

  def vaccine_methods = vaccines.map(&:method).uniq

  def has_multiple_vaccine_methods?
    # TODO: Ideally this would work as below, however that doesn't work well
    #  in a list as it results in N+1 issues, without deeply pre-fetching
    #  the vaccines which is a lot of data.

    # vaccine_methods.length > 1

    flu?
  end

  def available_delivery_methods
    vaccines.flat_map(&:available_delivery_methods).uniq
  end

  def available_delivery_sites
    vaccines.flat_map(&:available_delivery_sites).uniq
  end

  def default_dose_sequence = hpv? || flu? ? 1 : nil

  MAXIMUM_DOSE_SEQUENCES = {
    "flu" => 2,
    "hpv" => 3,
    "menacwy" => 3,
    "mmr" => 2,
    "td_ipv" => 5
  }.freeze

  def maximum_dose_sequence
    MAXIMUM_DOSE_SEQUENCES.fetch(type)
  end

  IMPORT_NAMES = {
    "flu" => %w[Flu],
    "hpv" => %w[HPV],
    "menacwy" => %w[ACWYX4 MenACWY],
    "mmr" => %w[MMR],
    "td_ipv" => %w[3-in-1 Td/IPV]
  }.freeze

  def import_names
    IMPORT_NAMES.fetch(type)
  end

  SNOMED_TARGET_DISEASE_CODES = {
    "hpv" => "240532009",
    "flu" => "6142004"
  }.freeze

  def snomed_target_disease_code
    SNOMED_TARGET_DISEASE_CODES.fetch(type)
  end

  SNOMED_TARGET_DISEASE_TERMS = {
    "hpv" => "Human papillomavirus infection",
    "flu" => "Influenza"
  }.freeze

  def snomed_target_disease_term
    SNOMED_TARGET_DISEASE_TERMS.fetch(type)
  end

  SNOMED_TARGET_DISEASE_NAMES = { "flu" => "FLU" }.freeze

  def snomed_target_disease_name
    SNOMED_TARGET_DISEASE_NAMES.fetch(type)
  end

  def can_sync_to_immunisations_api? = hpv? || flu?

  def can_search_in_immunisations_api? = flu?

  private

  def fhir_mapper = @fhir_mapper ||= FHIRMapper::Programme.new(self)
end
