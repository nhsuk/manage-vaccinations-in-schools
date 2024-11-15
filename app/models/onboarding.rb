# frozen_string_literal: true

class Onboarding
  include ActiveModel::Model

  validates :organisation, presence: true
  validates :programmes, presence: true
  validates :teams, presence: true
  validates :schools, presence: true
  validates :clinics, presence: true

  def initialize(hash)
    config = hash.deep_symbolize_keys

    @organisation = Organisation.new(config.fetch(:organisation, {}))

    @programmes =
      config
        .fetch(:programmes, [])
        .map do |type|
          ExistingProgramme.new(type:, organisation: @organisation)
        end

    teams_by_name =
      config
        .fetch(:teams, {})
        .transform_values do |team_config|
          Team.new(**team_config, organisation:)
        end

    @teams = teams_by_name.values

    @users =
      config
        .fetch(:users, [])
        .map do |user_config|
          User.new(**user_config, organisations: [organisation])
        end

    @schools =
      config
        .fetch(:schools, {})
        .flat_map do |team_name, school_urns|
          team = teams_by_name[team_name]
          school_urns.map { |urn| ExistingSchool.new(urn:, team:) }
        end

    @clinics =
      config
        .fetch(:clinics, {})
        .flat_map do |team_name, clinic_configs|
          team = teams_by_name[team_name]
          clinic_configs.map do |clinic_config|
            Location.new(**clinic_config, type: :community_clinic, team:)
          end
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
      organisation.generic_clinic
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

    attr_accessor :urn, :team

    validates :existing_team, absence: true
    validates :location, presence: true
    validates :team, presence: true

    def location
      @location ||= Location.school.find_by(urn:)
    end

    def existing_team
      location&.team
    end

    def save!
      location.update!(team:)
    end
  end
end
