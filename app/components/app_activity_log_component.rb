# frozen_string_literal: true

class AppActivityLogComponent < ViewComponent::Base
  erb_template <<-ERB
    <% events_by_day.each do |day, events| %>
      <h3 class="nhsuk-heading-xs nhsuk-u-secondary-text-colour
                 nhsuk-u-font-weight-normal">
        <%= day.to_fs(:long) %>
      </h3>

      <% events.each do |event| %>
        <%= render AppLogEventComponent.new(card: true, **event) %>
      <% end %>
    <% end %>
  ERB

  def initialize(team:, patient: nil, patient_session: nil)
    if patient.nil? && patient_session.nil?
      raise "Pass either a patient or a patient session."
    elsif patient && patient_session
      raise "Pass only a patient or a patient session."
    end

    @patient = patient || patient_session.patient
    @patient_sessions =
      patient_session ? [patient_session] : patient.patient_sessions

    @consents =
      @patient.consents.includes(
        :consent_form,
        :parent,
        :recorded_by,
        :programme,
        patient: :parent_relationships
      )

    @gillick_assessments =
      (patient || patient_session)
        .gillick_assessments
        .includes(:performed_by)
        .order(:created_at)

    @notes =
      (patient || patient_session).notes.includes(
        :created_by,
        :patient,
        session: :programmes
      )

    @notify_log_entries = @patient.notify_log_entries.includes(:sent_by)

    @pre_screenings =
      (patient || patient_session).pre_screenings.includes(:performed_by)

    @session_attendances =
      (patient || patient_session).session_attendances.includes(:location)

    @triages = @patient.triages.includes(:performed_by)

    @vaccination_records =
      @patient.vaccination_records.with_discarded.includes(
        :performed_by_user,
        :vaccine
      )

    @patient_specific_directions = @patient.patient_specific_directions

    @archive_reasons = @patient.archive_reasons.where(team:)
  end

  attr_reader :archive_reasons,
              :consents,
              :gillick_assessments,
              :notes,
              :notify_log_entries,
              :patient,
              :patient_sessions,
              :patient_specific_directions,
              :pre_screenings,
              :session_attendances,
              :triages,
              :vaccination_records

  def events_by_day
    all_events.sort_by { -it[:at].to_i }.group_by { it[:at].to_date }
  end

  def all_events
    [
      archive_events,
      attendance_events,
      consent_events,
      expiration_events,
      gillick_assessment_events,
      note_events,
      notify_events,
      pre_screening_events,
      session_events,
      triage_events,
      vaccination_events
    ].flatten
  end

  def archive_events
    archive_reasons.flat_map do |archive_reason|
      {
        title: "Record archived: #{archive_reason.human_enum_name(:type)}",
        body: archive_reason.other_details,
        at: archive_reason.created_at,
        by: archive_reason.created_by
      }
    end
  end

  def consent_events
    consents.flat_map do |consent|
      events = []

      original_response = consent.withdrawn? ? "given" : consent.response

      events << if (consent_form = consent.consent_form)
        {
          title: "Consent #{original_response}",
          at: consent_form.recorded_at,
          by: consent_form.parent_relationship.label_with_parent,
          programmes: programmes_for(consent)
        }
      else
        {
          title:
            "Consent #{original_response} by #{consent.name} (#{consent.who_responded})",
          at: consent.submitted_at,
          by: consent.recorded_by,
          programmes: programmes_for(consent)
        }
      end

      if consent.matched_manually?
        events << {
          title: "Consent response manually matched with child record",
          at: consent.created_at,
          by: consent.recorded_by,
          programmes: programmes_for(consent)
        }
      end

      if consent.invalidated?
        events << {
          title: "Consent from #{consent.name} invalidated",
          at: consent.invalidated_at,
          programmes: programmes_for(consent)
        }
      end

      if consent.withdrawn?
        events << {
          title: "Consent from #{consent.name} withdrawn",
          at: consent.withdrawn_at,
          programmes: programmes_for(consent)
        }
      end

      events
    end
  end

  def expiration_events
    all_programmes = Programme.all.to_a

    AcademicYear.all.flat_map do |academic_year|
      next [] if academic_year >= AcademicYear.current

      not_vaccinated_programmes =
        all_programmes.reject do |programme|
          patient.vaccination_status(programme:, academic_year:).vaccinated?
        end

      vaccinated_but_seasonal_programmes =
        all_programmes.select do |programme|
          patient.vaccination_status(programme:, academic_year:).vaccinated? &&
            programme.seasonal?
        end

      expired_items =
        {
          vaccinated_but_seasonal: vaccinated_but_seasonal_programmes,
          not_vaccinated: not_vaccinated_programmes
        }.transform_values do |programmes|
          get_expired_items(academic_year:, programmes:)
        end

      expired_items.map do |category, expired_items_in_category|
        expired_item_names = []
        if expired_items_in_category[:consents].any?
          expired_item_names += ["consent", "health information"]
        end
        if expired_items_in_category[:triages].any?
          expired_item_names << "triage outcome"
        end
        if expired_items_in_category[:patient_specific_directions].any?
          expired_item_names << "PSD status"
        end

        next [] if expired_item_names.empty?

        title =
          "#{
            expired_item_names.to_sentence(
              words_connector: ", ",
              last_word_connector: " and "
            ).upcase_first
          } expired"

        body =
          case category
          when :not_vaccinated
            "#{@patient.full_name} was not vaccinated."
          when :vaccinated_but_seasonal
            "#{@patient.full_name} was vaccinated."
          end

        programmes = expired_items_in_category.values.flatten.uniq

        {
          title:,
          body:,
          at:
            academic_year.to_academic_year_date_range.end.end_of_day - 1.second,
          programmes:
        }
      end
    end
  end

  def gillick_assessment_events
    gillick_assessments.each_with_index.map do |gillick_assessment, index|
      action = index.zero? ? "Completed" : "Updated"
      outcome =
        (
          if gillick_assessment.gillick_competent?
            "Gillick competent"
          else
            "not Gillick competent"
          end
        )

      {
        title: "#{action} Gillick assessment as #{outcome}",
        body: gillick_assessment.notes,
        at: gillick_assessment.created_at,
        by: gillick_assessment.performed_by,
        programmes: programmes_for(gillick_assessment)
      }
    end
  end

  def note_events
    notes.map do |note|
      {
        title: "Note",
        body: note.body,
        at: note.created_at,
        by: note.created_by,
        programmes: programmes_for(note)
      }
    end
  end

  def notify_events
    notify_log_entries.map do |notify_log_entry|
      {
        title: "#{notify_log_entry.title} sent",
        body: patient.restricted? ? "" : notify_log_entry.recipient,
        at: notify_log_entry.created_at,
        by: notify_log_entry.sent_by,
        programmes: programmes_for(notify_log_entry)
      }
    end
  end

  def pre_screening_events
    pre_screenings.map do |pre_screening|
      {
        title: "Completed pre-screening checks",
        body: pre_screening.notes,
        at: pre_screening.created_at,
        by: pre_screening.performed_by,
        programmes: programmes_for(pre_screening)
      }
    end
  end

  def session_events
    patient_sessions.map do |patient_session|
      [
        {
          title: "Added to the session at #{patient_session.location.name}",
          at: patient_session.created_at,
          programmes: programmes_for(patient_session)
        }
      ]
    end
  end

  def triage_events
    triages.map do |triage|
      programmes = programmes_for(triage)
      title = "Triaged decision: #{triage.human_enum_name(:status)}"
      title +=
        " with #{triage.human_enum_name(:vaccine_method)}" if triage.vaccine_method.present? &&
        programmes.first.has_multiple_vaccine_methods?
      {
        title:,
        body: triage.notes,
        at: triage.created_at,
        by: triage.performed_by,
        programmes:
      }
    end
  end

  def vaccination_events
    vaccination_records.flat_map do |vaccination_record|
      title =
        if vaccination_record.administered?
          if (vaccine = vaccination_record.vaccine)
            "Vaccinated with #{vaccine.brand}"
          else
            "Vaccinated"
          end
        else
          "Vaccination not given: #{vaccination_record.human_enum_name(:outcome)}"
        end

      kept = {
        title:,
        body: vaccination_record.notes,
        at: vaccination_record.performed_at,
        by: vaccination_record.performed_by,
        programmes: programmes_for(vaccination_record)
      }

      discarded =
        if vaccination_record.discarded?
          {
            title: "Vaccination record archived",
            at: vaccination_record.discarded_at,
            programmes: programmes_for(vaccination_record)
          }
        end

      [kept, discarded].compact
    end
  end

  def attendance_events
    session_attendances.map do |session_attendance|
      title =
        (
          if session_attendance.attending?
            "Attended session"
          else
            "Absent from session"
          end
        )

      title += " at #{session_attendance.location.name}"

      { title:, at: session_attendance.created_at }
    end
  end

  def programmes_for(object)
    if object.respond_to?(:programme_ids)
      object.programme_ids.map { programmes_by_id.fetch(it) }
    elsif object.respond_to?(:programme_id)
      [programmes_by_id.fetch(object.programme_id)]
    else
      object.programmes
    end
  end

  def programmes_by_id
    @programmes_by_id ||= Programme.all.index_by(&:id)
  end

  private

  def filter_expired(items, academic_year:, programmes:)
    items
      .select { it.academic_year == academic_year }
      .flat_map { programmes_for(it) }
      .select { programmes.include?(it) }
  end

  def get_expired_items(academic_year:, programmes:)
    {
      consents:,
      triages:,
      patient_specific_directions:
    }.transform_values do |items|
      filter_expired(items, academic_year:, programmes:)
    end
  end
end
