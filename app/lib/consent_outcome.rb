# frozen_string_literal: true

class ConsentOutcome
  def initialize(patients:)
    @patients = patients
  end

  STATUSES = [
    NO_RESPONSE = :no_response,
    CONFLICTS = :conflicts,
    GIVEN = :given,
    REFUSED = :refused
  ].freeze

  def no_response?(patient, programme:)
    status(patient, programme:) == NO_RESPONSE
  end

  def conflicts?(patient, programme:)
    status(patient, programme:) == CONFLICTS
  end

  def given?(patient, programme:)
    status(patient, programme:) == GIVEN
  end

  def refused?(patient, programme:)
    status(patient, programme:) == REFUSED
  end

  def status(patient, programme:)
    if consent_given?(patient, programme:)
      GIVEN
    elsif consent_refused?(patient, programme:)
      REFUSED
    elsif consent_conflicts?(patient, programme:)
      CONFLICTS
    else
      NO_RESPONSE
    end
  end

  def needs_triage?(patient, programme:)
    health_answers =
      if (self_response = self_consent(patient, programme:))
        self_response.first == "given" ? [self_response.second] : []
      else
        parental_consents(patient, programme:)
          .select { it.first == "given" }
          .map(&:second)
      end

    health_answers.flatten.any? { it.response&.downcase == "yes" }
  end

  private

  attr_reader :patients

  def consent_given?(patient, programme:)
    if (self_response = self_consent(patient, programme:))
      self_response.first == "given"
    else
      parental_consents(patient, programme:)&.map(&:first)&.all?("given")
    end
  end

  def consent_refused?(patient, programme:)
    parental_consents(patient, programme:)&.map(&:first)&.all?("refused")
  end

  def consent_conflicts?(patient, programme:)
    parental_consents(patient, programme:)&.map(&:first)&.any?("refused") &&
      parental_consents(patient, programme:).map(&:first).any?("given")
  end

  def self_consent(patient, programme:)
    consents.dig(patient.id, programme.id, :self)
  end

  def parental_consents(patient, programme:)
    consents
      .dig(patient.id, programme.id)
      &.filter_map { it.second if it.first != :self }
  end

  def consents
    @consents ||=
      Consent
        .where(patient: patients)
        .not_invalidated
        .eager_load(:parent)
        .order(:"parents.full_name", :programme_id, created_at: :desc)
        .pluck(
          Arel.sql(
            "DISTINCT ON (parents.full_name, programme_id) patient_id, " \
              "programme_id, parent_id, response, health_answers"
          )
        )
        .each_with_object({}) do |row, hash|
          hash[row.first] ||= {}
          hash[row.first][row.second] ||= {}
          hash[row.first][row.second][
            row.third.nil? ? :self : row.third
          ] = row.drop(3)
        end
  end
end
