# frozen_string_literal: true

class StatusGenerator::Session
  def initialize(
    session_id:,
    academic_year:,
    session_attendance:,
    programme:,
    consents:,
    triages:,
    vaccination_records:
  )
    @session_id = session_id
    @academic_year = academic_year
    @session_attendance = session_attendance
    @programme = programme
    @consents = consents
    @triages = triages
    @vaccination_records = vaccination_records
  end

  def status
    if status_should_be_vaccinated?
      :vaccinated
    elsif status_should_be_already_had?
      :already_had
    elsif status_should_be_had_contraindications?
      :had_contraindications
    elsif status_should_be_refused?
      :refused
    elsif status_should_be_absent_from_session?
      :absent_from_session
    elsif status_should_be_unwell?
      :unwell
    else
      :none_yet
    end
  end

  def status_changed_at
    if status_should_be_vaccinated?
      vaccination_date
    elsif status_should_be_already_had?
      already_had_date
    elsif status_should_be_had_contraindications?
      contraindications_date
    elsif status_should_be_refused?
      refusal_date
    elsif status_should_be_absent_from_session?
      absence_date
    elsif status_should_be_unwell?
      unwell_date
    end
  end

  private

  attr_reader :session_id,
              :academic_year,
              :session_attendance,
              :programme,
              :consents,
              :triages,
              :vaccination_records

  def status_should_be_vaccinated?
    vaccination_record&.administered?
  end

  def vaccination_date
    vaccination_record.performed_at
  end

  def status_should_be_already_had?
    vaccination_record&.already_had?
  end

  def already_had_date
    vaccination_record.performed_at
  end

  def status_should_be_had_contraindications?
    vaccination_record&.contraindications? || triage&.do_not_vaccinate?
  end

  def contraindications_date
    [
      if vaccination_record&.contraindications?
        vaccination_record.performed_at
      end,
      (triage.created_at if triage&.do_not_vaccinate?)
    ].compact.min
  end
  def status_should_be_refused?
    vaccination_record&.refused? ||
      (latest_consents.any? && latest_consents.all?(&:response_refused?))
  end

  def refusal_date
    [
      (vaccination_record.performed_at if vaccination_record&.refused?),
      if latest_consents.any? && latest_consents.all?(&:response_refused?)
        latest_consents.map(&:submitted_at).min
      end
    ].compact.min
  end

  def status_should_be_absent_from_session?
    vaccination_record&.absent_from_session? ||
      session_attendance&.attending == false
  end

  def absence_date
    [
      if vaccination_record&.absent_from_session?
        vaccination_record.performed_at
      end,
      (session_attendance.created_at if session_attendance&.attending == false)
    ].compact.min
  end

  def status_should_be_unwell?
    vaccination_record&.not_well?
  end

  def unwell_date
    vaccination_record.performed_at
  end

  def latest_consents
    @latest_consents ||=
      ConsentGrouper.call(consents, programme_id: programme.id, academic_year:)
  end

  def triage
    @triage ||=
      TriageFinder.call(triages, programme_id: programme.id, academic_year:)
  end

  def vaccination_record
    @vaccination_record ||=
      if session_id
        vaccination_records.find do
          it.programme_id == programme.id && it.session_id == session_id
        end
      end
  end
end
