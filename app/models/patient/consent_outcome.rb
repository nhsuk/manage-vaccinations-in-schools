# frozen_string_literal: true

class Patient::ConsentOutcome
  def initialize(patient)
    @patient = patient
  end

  STATUSES = [
    NO_RESPONSE = :no_response,
    CONFLICTS = :conflicts,
    GIVEN = :given,
    REFUSED = :refused
  ].freeze

  def no_response?(programme) = status[programme] == NO_RESPONSE

  def conflicts?(programme) = status[programme] == CONFLICTS

  def given?(programme) = status[programme] == GIVEN

  def refused?(programme) = status[programme] == REFUSED

  def status
    @status ||=
      Hash.new do |hash, programme|
        hash[programme] = programme_status(programme)
      end
  end

  def all
    @all ||=
      Hash.new do |hash, programme|
        hash[programme] = all_by_programme_id.fetch(programme.id, [])
      end
  end

  def latest
    @latest ||=
      Hash.new do |hash, programme|
        hash[programme] = all[programme]
          .reject(&:invalidated?)
          .select { it.response_given? || it.response_refused? }
          .group_by(&:name)
          .map { it.second.max_by(&:created_at) }
      end
  end

  private

  attr_reader :patient

  def programme_status(programme)
    if consent_given?(programme)
      GIVEN
    elsif consent_refused?(programme)
      REFUSED
    elsif consent_conflicts?(programme)
      CONFLICTS
    else
      NO_RESPONSE
    end
  end

  def consent_given?(programme)
    if self_consents(programme).any?
      self_consents(programme).all?(&:response_given?)
    else
      latest[programme].any? && latest[programme].all?(&:response_given?)
    end
  end

  def consent_refused?(programme)
    latest[programme].any? && latest[programme].all?(&:response_refused?)
  end

  def consent_conflicts?(programme)
    if self_consents(programme).any?
      self_consents(programme).any?(&:response_refused?) &&
        self_consents(programme).any?(&:response_given?)
    else
      latest[programme].any?(&:response_refused?) &&
        latest[programme].any?(&:response_given?)
    end
  end

  def self_consents(programme)
    latest[programme].select(&:via_self_consent?)
  end

  def all_by_programme_id
    @all_by_programme_id ||= patient.consents.group_by(&:programme_id)
  end
end
