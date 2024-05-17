class AppConsentStatusComponent < ViewComponent::Base
  def call
    if @patient_session.consent_given?
      blue_tick "Given"
    elsif @patient_session.consent_refused?
      red_cross "Refused"
    elsif @patient_session.consent_conflicts?
      red_cross "Conflicts"
    end
  end

  def initialize(patient_session:)
    super

    @patient_session = patient_session
  end

  private

  def blue_tick(content)
    template = <<-ERB
      <p class="app-status app-status--blue">
        <svg class="nhsuk-icon nhsuk-icon__tick"
             xmlns="http://www.w3.org/2000/svg"
             viewBox="0 0 24 24"
             aria-hidden="true">
          <path d="M18.4 7.8l-8.5 8.4L5.6 12"
                fill="none"
                stroke="currentColor"
                stroke-width="4"
                stroke-linecap="round"></path>
        </svg>
        #{content}
      </p>
    ERB
    template.html_safe
  end

  def red_cross(content)
    template = <<-ERB
      <p class="app-status app-status--red">
        <svg class="nhsuk-icon nhsuk-icon__cross"
             xmlns="http://www.w3.org/2000/svg"
             viewBox="0 0 24 24"
             aria-hidden="true">
          <path d="M18.6 6.5c.5.5.5 1.5 0 2l-4 4 4 4c.5.6.5 1.4 0 2-.4.4-.7.4-1
                  .4-.5 0-.9 0-1.2-.3l-3.9-4-4 4c-.3.3-.5.3-1
                  .3a1.5 1.5 0 0 1-1-2.4l3.9-4-4-4c-.5-.5-.5-1.4 0-2
                  .6-.7 1.5-.7 2.2 0l3.9 3.9 4-4c.6-.6 1.4-.6 2 0Z"
              fill="currentColor"></path>
        </svg>
        #{content}
      </p>
    ERB
    template.html_safe
  end
end
