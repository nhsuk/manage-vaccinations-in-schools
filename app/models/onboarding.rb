# frozen_string_literal: true

class Onboarding
  include ActiveModel::Model

  CLINIC_ATTRIBUTES = %i[
    address_line_1
    address_line_2
    address_postcode
    address_town
    name
    ods_code
    url
    year_groups
  ].freeze

  ORGANISATION_ATTRIBUTES = %i[ods_code].freeze

  TEAM_ATTRIBUTES = %i[
    careplus_venue_code
    days_before_consent_reminders
    days_before_consent_requests
    days_before_invitations
    email
    name
    phone
    phone_instructions
    privacy_notice_url
    privacy_policy_url
    reply_to_id
    workgroup
  ].freeze

  SUBTEAM_ATTRIBUTES = %i[
    email
    name
    phone
    phone_instructions
    reply_to_id
  ].freeze

  USER_ATTRIBUTES = %i[
    email
    fallback_role
    family_name
    given_name
    password
  ].freeze

  validates :team, presence: true
  validates :programmes, presence: true
  validates :subteams, presence: true
  validates :schools, presence: true
  validates :clinics, presence: true

  def initialize(hash)
    config = hash.deep_symbolize_keys

    @organisation =
      Organisation.find_or_initialize_by(
        config.fetch(:organisation, {}).slice(*ORGANISATION_ATTRIBUTES)
      )

    @team =
      Team.new(
        **config.fetch(:team, {}).slice(*TEAM_ATTRIBUTES),
        organisation: @organisation,
        programme_types: []
      )

    @programmes =
      config
        .fetch(:programmes, [])
        .map { |type| ExistingProgramme.new(type:, team:) }

    subteams_by_name =
      config
        .fetch(:subteams, {})
        .transform_values { it.slice(*SUBTEAM_ATTRIBUTES) }
        .transform_values { Subteam.new(**it, team:) }

    @subteams = subteams_by_name.values

    @users =
      config
        .fetch(:users, [])
        .map { it.slice(*USER_ATTRIBUTES) }
        .map do |attributes|
          User
            .find_or_initialize_by(email: attributes[:email])
            .tap { it.assign_attributes(attributes) }
        end

    @schools =
      config
        .fetch(:schools, {})
        .flat_map do |team_name, school_urns|
          subteam = subteams_by_name[team_name]
          school_urns.map do |urn|
            ExistingSchool.new(urn:, subteam:, programmes:)
          end
        end

    @clinics =
      config
        .fetch(:clinics, {})
        .flat_map do |team_name, clinic_configs|
          subteam = subteams_by_name[team_name]
          clinic_configs
            .map { it.slice(*CLINIC_ATTRIBUTES) }
            .map { Location.new(**it, type: :community_clinic, subteam:) }
        end
  end

  def valid?(context = nil)
    ([super] + models.map(&:valid?)).all?
  end

  def invalid?(context = nil)
    ([super] + models.map(&:invalid?)).any?
  end

  def errors
    super.tap do |errors|
      merge_errors_from([organisation], errors:, name: "organisation")
      merge_errors_from([team], errors:, name: "team")
      merge_errors_from(programmes, errors:, name: "programme")
      merge_errors_from(subteams, errors:, name: "subteam")
      merge_errors_from(users, errors:, name: "user")
      merge_errors_from(schools, errors:, name: "school")
      merge_errors_from(clinics, errors:, name: "clinic")
    end
  end

  def save!(create_sessions_for_previous_academic_year: false)
    ActiveRecord::Base.transaction do
      models.each(&:save!)

      # Reload to ensure the programmes are loaded.
      team.reload

      GenericClinicFactory.call(team:, academic_year:)

      @users.each { |user| user.teams << team }

      TeamSessionsFactory.call(team, academic_year:)

      if create_sessions_for_previous_academic_year
        GenericClinicFactory.call(team:, academic_year: academic_year - 1)
        TeamSessionsFactory.call(team, academic_year: academic_year - 1)
      end
    end
  end

  private

  attr_reader :organisation,
              :team,
              :programmes,
              :subteams,
              :users,
              :schools,
              :clinics

  def academic_year = AcademicYear.pending

  def models
    [organisation] + [team] + programmes + subteams + users + schools + clinics
  end

  def merge_errors_from(objects, errors:, name:)
    objects.each_with_index do |obj, index|
      obj.errors.each do |error|
        prefix =
          if objects.count == 1
            name
          else
            "#{name}.#{index}"
          end

        errors.import(error, attribute: "#{prefix}.#{error.attribute}")
      end
    end
  end

  class ExistingProgramme
    include ActiveModel::Model

    attr_accessor :type, :team

    validates :programme, presence: true

    def programme
      @programme ||= Programme.find_by(type:)
    end

    def save!
      team.update!(programme_types: (team.programme_types + [type]).sort.uniq)
    end
  end

  class ExistingSchool
    include ActiveModel::Model

    attr_accessor :urn, :subteam, :programmes

    validates :existing_subteam, absence: true
    validates :location, presence: true
    validates :subteam, presence: true
    validates :status, inclusion: %w[open opening]

    def location
      @location ||= Location.school.find_by_urn_and_site(urn)
    end

    delegate :status, to: :location, allow_nil: true

    def existing_subteam
      location&.subteam
    end

    def save!
      academic_year = AcademicYear.pending

      location.update!(subteam:)
      location.import_year_groups_from_gias!(academic_year:)
      location.import_default_programme_year_groups!(
        programmes.map(&:programme),
        academic_year:
      )
    end
  end
end
