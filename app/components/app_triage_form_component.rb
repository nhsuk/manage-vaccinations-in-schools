class AppTriageFormComponent < ViewComponent::Base
  def initialize(patient_session:, url:, triage: nil, bold_legend: false)
    super

    @patient_session = patient_session
    @triage =
      triage ||
        Triage.new.tap do |t|
          if patient_session.triage.any?
            t.status = patient_session.triage.order(:created_at).last.status
          end
        end
    @url = url
    @bold_legend = bold_legend
  end

  private

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
