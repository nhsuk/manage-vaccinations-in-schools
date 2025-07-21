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

  ORGANISATION_ATTRIBUTES = %i[
    careplus_venue_code
    days_before_consent_reminders
    days_before_consent_requests
    days_before_invitations
    email
    name
    ods_code
    phone
    phone_instructions
    privacy_notice_url
    privacy_policy_url
    reply_to_id
  ].freeze

  TEAM_ATTRIBUTES = %i[email name phone phone_instructions reply_to_id].freeze

  USER_ATTRIBUTES = %i[
    email
    fallback_role
    family_name
    given_name
    password
  ].freeze

  validates :organisation, presence: true
  validates :programmes, presence: true
  validates :teams, presence: true
  validates :schools, presence: true
  validates :clinics, presence: true

  def initialize(hash)
    config = hash.deep_symbolize_keys

    @organisation =
      Organisation.new(
        config.fetch(:organisation, {}).slice(*ORGANISATION_ATTRIBUTES)
      )

    @programmes =
      config
        .fetch(:programmes, [])
        .map { |type| ExistingProgramme.new(type:, organisation:) }

    teams_by_name =
      config
        .fetch(:teams, {})
        .transform_values { it.slice(*TEAM_ATTRIBUTES) }
        .transform_values { Team.new(**it, organisation:) }

    @teams = teams_by_name.values

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
          team = teams_by_name[team_name]
          school_urns.map { |urn| ExistingSchool.new(urn:, team:, programmes:) }
        end

    @clinics =
      config
        .fetch(:clinics, {})
        .flat_map do |team_name, clinic_configs|
          team = teams_by_name[team_name]
          clinic_configs
            .map { it.slice(*CLINIC_ATTRIBUTES) }
            .map { Location.new(**it, type: :community_clinic, team:) }
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
      merge_errors_from(programmes, errors:, name: "programme")
      merge_errors_from(teams, errors:, name: "team")
      merge_errors_from(users, errors:, name: "user")
      merge_errors_from(schools, errors:, name: "school")
      merge_errors_from(clinics, errors:, name: "clinic")
    end
  end

  def save!
    ActiveRecord::Base.transaction do
      models.each(&:save!)

      # Reload to ensure the programmes are loaded.
      GenericClinicFactory.call(organisation: organisation.reload)

      @users.each { |user| user.organisations << organisation }
      UnscheduledSessionsFactory.new.call
    end
  end

  private

  attr_reader :organisation, :programmes, :teams, :users, :schools, :clinics

  def models
    [organisation] + programmes + teams + users + schools + clinics
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

    attr_accessor :type, :organisation

    validates :programme, presence: true

    def programme
      @programme ||= Programme.find_by(type:)
    end

    def save!
      OrganisationProgramme.create!(organisation:, programme:)
    end
  end

  class ExistingSchool
    include ActiveModel::Model

    attr_accessor :urn, :team, :programmes

    validates :existing_team, absence: true
    validates :location, presence: true
    validates :team, presence: true
    validates :status, inclusion: %w[open opening]

    def location
      @location ||= Location.school.find_by(urn:)
    end

    delegate :status, to: :location, allow_nil: true

    def existing_team
      location&.team
    end

    def save!
      location.update!(team:)
      location.create_default_programme_year_groups!(
        programmes.map(&:programme)
      )
    end
  end
end
