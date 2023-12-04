class AppPatientTableComponent < ViewComponent::Base
  def call
    govuk_table(classes: "app-table--patients") do |table|
      table.with_head do |head|
        head.with_row do |row|
          @columns.each { |column| row.with_cell(text: column_name(column)) }
        end
      end

      table.with_body do |body|
        @patient_sessions.each do |patient_session|
          body.with_row do |row|
            @columns.each do |column|
              row.with_cell(text: column_value(patient_session, column))
            end
          end
        end
      end
    end
  end

  def initialize(patient_sessions:, columns: %i[name dob], route: nil)
    super

    @patient_sessions = patient_sessions
    @columns = columns
    @route = route
  end

  private

  def column_name(column)
    { name: "Name", dob: "Date of birth", reason: "Reason for refusal" }[column]
  end

  def column_value(patient_session, column)
    case column
    when :name
      patient_link(patient_session)
    when :dob
      patient_session.patient.dob.to_fs(:nhsuk_date)
    when :reason
      patient_session
        .consents
        .map { |c| c.human_enum_name(:reason_for_refusal) }
        .join("<br />")
        .html_safe
    end
  end

  def patient_link(patient_session)
    if @route == :consent
      govuk_link_to patient_session.patient.full_name,
                    session_patient_consents_path(
                      patient_session.session,
                      patient_session.patient
                    )
    else
      raise ArgumentError, "Unknown route: #{@route}"
    end
  end
end
