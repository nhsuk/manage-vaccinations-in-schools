# frozen_string_literal: true

# == Schema Information
#
# Table name: organisations
#
#  id         :bigint           not null, primary key
#  ods_code   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_organisations_on_ods_code  (ods_code) UNIQUE
#
class Organisation < ApplicationRecord
  include ContributesToPatientTeams
  include ODSCodeConcern

  class ActiveRecord_Relation < ActiveRecord::Relation
    include ContributesToPatientTeams::Relation
  end

  audited
  has_associated_audits

  has_many :teams

  validates :ods_code, presence: true

  delegate :fhir_reference, to: :fhir_mapper

  class << self
    delegate :fhir_reference, to: FHIRMapper::Organisation
  end

  private

  def fhir_mapper
    @fhir_mapper ||= FHIRMapper::Organisation.new(self)
  end
end
