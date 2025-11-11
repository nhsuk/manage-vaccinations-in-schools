# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id                        :bigint           not null, primary key
#  address_line_1            :text
#  address_line_2            :text
#  address_postcode          :text
#  address_town              :text
#  gias_establishment_number :integer
#  gias_local_authority_code :integer
#  gias_year_groups          :integer          default([]), not null, is an Array
#  name                      :text             not null
#  ods_code                  :string
#  site                      :string
#  status                    :integer          default("unknown"), not null
#  systm_one_code            :string
#  type                      :integer          not null
#  url                       :text
#  urn                       :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  subteam_id                :bigint
#
# Indexes
#
#  index_locations_on_ods_code        (ods_code) UNIQUE
#  index_locations_on_subteam_id      (subteam_id)
#  index_locations_on_systm_one_code  (systm_one_code) UNIQUE
#  index_locations_on_urn             (urn) UNIQUE WHERE (site IS NULL)
#  index_locations_on_urn_and_site    (urn,site) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (subteam_id => subteams.id)
#
class Location < ApplicationRecord
  include AddressConcern
  include ContributesToPatientTeams
  include HasLocationProgrammeYearGroups
  include ODSCodeConcern

  class ActiveRecord_Relation < ActiveRecord::Relation
    include ContributesToPatientTeams::Relation
  end

  self.inheritance_column = nil

  audited associated_with: :subteam
  has_associated_audits

  belongs_to :subteam, optional: true

  belongs_to :local_authority,
             foreign_key: :gias_local_authority_code,
             primary_key: :gias_code,
             optional: true

  has_many :location_year_groups,
           class_name: "Location::YearGroup",
           dependent: :destroy

  has_many :attendance_records
  has_many :consent_forms
  has_many :patient_locations
  has_many :sessions

  has_one :team, through: :subteam

  has_many :location_programme_year_groups,
           -> { includes(:location_year_group) },
           through: :location_year_groups

  # This is based on the school statuses from the DfE GIAS data.
  enum :status,
       { unknown: 0, open: 1, closed: 2, closing: 3, opening: 4 },
       default: :unknown

  enum :type,
       { school: 0, generic_clinic: 1, community_clinic: 2, gp_practice: 3 }

  scope :where_urn_and_site,
        ->(urn_and_site) do
          where(
            "CONCAT(locations.urn, locations.site) = ?",
            urn_and_site&.to_s&.strip
          )
        end

  scope :has_gias_year_groups,
        ->(values) { where("ARRAY[?]::integer[] <@ gias_year_groups", values) }

  scope :search_by_name,
        ->(query) do
          # Trigram matching requires at least 3 characters
          if query.length < 3
            where("locations.name ILIKE :like_query", like_query: "#{query}%")
          else
            where("SIMILARITY(locations.name, ?) > 0.3", query).order(
              Arel.sql("SIMILARITY(locations.name, ?) DESC", query)
            )
          end
        end

  scope :clinic, -> { generic_clinic.or(community_clinic) }

  validates :name, presence: true
  validates :url, url: true, allow_nil: true

  validates :urn, uniqueness: true, allow_nil: true, if: -> { site.nil? }
  validates :site, uniqueness: { scope: :urn }, allow_nil: true

  with_options if: :community_clinic? do
    validates :ods_code, exclusion: { in: :organisation_ods_code }
  end

  with_options if: :generic_clinic? do
    validates :ods_code, absence: true
    validates :subteam, presence: true
  end

  with_options if: :gp_practice? do
    validates :ods_code, presence: true
  end

  with_options if: :school? do
    validates :gias_establishment_number, presence: true
    validates :gias_local_authority_code, presence: true
    validates :urn, presence: true
  end

  normalizes :site, with: -> { it.blank? ? nil : it.strip }
  normalizes :urn, with: -> { it.blank? ? nil : it.strip }

  delegate :fhir_reference, to: :fhir_mapper

  def self.find_by_urn_and_site(urn_and_site)
    where_urn_and_site(urn_and_site).take
  end

  def self.find_by_urn_and_site!(urn_and_site)
    where_urn_and_site(urn_and_site).take!
  end

  def urn_and_site
    return nil if urn.nil? && site.nil?
    site.nil? ? urn : urn + site
  end

  def year_groups
    @year_groups ||= location_year_groups.pluck_values
  end

  def programmes
    location_programme_year_groups.map(&:programme).sort.uniq
  end

  def clinic? = generic_clinic? || community_clinic?

  def dfe_number
    "#{gias_local_authority_code}#{gias_establishment_number}" if school?
  end

  def as_json
    super.except(
      "created_at",
      "subteam_id",
      "systm_one_code",
      "updated_at"
    ).merge("is_attached_to_team" => !subteam_id.nil?)
  end

  def import_year_groups!(values, academic_year:, source:)
    Location::YearGroup.import!(
      %i[location_id academic_year value source],
      values.map { |value| [id, academic_year, value, source] },
      on_duplicate_key_ignore: true
    )
  end

  def import_year_groups_from_gias!(academic_year:)
    import_year_groups!(gias_year_groups, academic_year:, source: "gias")
  end

  def import_default_programme_year_groups!(programmes, academic_year:)
    year_group_ids =
      location_year_groups.where(academic_year:).pluck(:value, :id).to_h

    rows =
      programmes.flat_map do |programme|
        programme.default_year_groups.filter_map do |year_group|
          if (year_group_id = year_group_ids[year_group])
            [year_group_id, programme.type]
          end
        end
      end

    Location::ProgrammeYearGroup.import!(
      %i[location_year_group_id programme_type],
      rows,
      on_duplicate_key_ignore: true
    )
  end

  private

  def organisation_ods_code
    [subteam&.team&.organisation&.ods_code].compact
  end

  def fhir_mapper
    @fhir_mapper ||= FHIRMapper::Location.new(self)
  end
end
