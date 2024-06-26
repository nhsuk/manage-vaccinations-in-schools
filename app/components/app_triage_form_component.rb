class AppTriageFormComponent < ViewComponent::Base
  def initialize(patient_session:, triage:, section:, tab:, bold_legend: false)
    super

    @patient_session = patient_session
    @triage =
      triage ||
        Triage.new.tap do |t|
          if patient_session.triage.any?
            t.status = patient_session.triage.order(:created_at).last.status
          end
        end
    @section = section
    @tab = tab
    @bold_legend = bold_legend
  end

  private

  def url
    session_patient_triage_path(
      session,
      patient,
      @triage,
      section: @section,
      tab: @tab
    )
  end

  def patient
    @patient_session.patient
  end

  def session
    @patient_session.session
  end

  def fieldset_options
    {
      legend: {
        text: "Is it safe to vaccinate #{@patient_session.patient.first_name}?"
      }.merge(
        (
          if @bold_legend
            { tag: :h2 }
          else
            { size: "s", class: "app-fieldset__legend--reset" }
          end
        )
      )
    }
  end
end
