# frozen_string_literal: true

class Stats::Session
  def initialize(session, programme:)
    @session = session
    @programme = programme
  end

  def call
    stats = {
      total: patient_ids.size,
      needs_consent:
        programme_count_for(
          Patient::ProgrammeStatus::NEEDS_CONSENT_STATUSES.keys
        ),
      needs_triage:
        programme_count_for(
          Patient::ProgrammeStatus::NEEDS_TRIAGE_STATUSES.keys
        )
    }

    due_statuses.each do |due_status|
      options = DUE_PREDICATES.fetch(due_status)
      stats[due_status.to_sym] = programme_count_for(["due"], **options)
    end

    stats.merge(
      has_refusal:
        programme_count_for(
          Patient::ProgrammeStatus::HAS_REFUSAL_STATUSES.keys
        ),
      cannot_vaccinate:
        programme_count_for(
          Patient::ProgrammeStatus::CANNOT_VACCINATE_STATUSES.keys
        ),
      vaccinated:
        programme_count_for(Patient::ProgrammeStatus::VACCINATED_STATUSES.keys)
    )
  end

  def self.call(...) = new(...).call

  private

  attr_reader :session, :programme

  delegate :academic_year, :location, :team, to: :session

  def due_statuses
    if programme.flu?
      %w[due_nasal due_injection]
    elsif programme.mmr?
      %w[due_no_preference due_without_gelatine]
    else
      %w[due]
    end
  end

  DUE_PREDICATES = {
    "due" => {
    },
    "due_injection" => {
      vaccine_method: "injection"
    },
    "due_nasal" => {
      vaccine_method: "nasal"
    },
    "due_no_preference" => {
      without_gelatine: false
    },
    "due_without_gelatine" => {
      without_gelatine: true
    }
  }.freeze

  def programme_count_for(statuses, vaccine_method: nil, without_gelatine: nil)
    vaccine_method_value =
      if vaccine_method
        Patient::ProgrammeStatus.vaccine_methods.fetch(vaccine_method)
      end

    programme_counts.sum do |(counted_status, counted_vaccine_methods, counted_without_gelatine), count|
      next 0 unless counted_status.in?(statuses)

      unless vaccine_method_value.nil? ||
               counted_vaccine_methods.first == vaccine_method_value
        next 0
      end

      unless without_gelatine.nil? ||
               counted_without_gelatine == without_gelatine
        next 0
      end

      count
    end
  end

  def programme_counts
    @programme_counts ||=
      Patient::ProgrammeStatus
        .for_programme(programme)
        .where(patient_id: patient_ids, academic_year:)
        .group(:status, :vaccine_methods, :without_gelatine)
        .count
  end

  def patient_ids
    @patient_ids ||=
      session
        .patients
        .appear_in_programmes([programme], session:)
        .eligible_for_programme(programme, session:)
        .pluck(:id)
  end
end
