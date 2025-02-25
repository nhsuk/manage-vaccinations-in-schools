# frozen_string_literal: true

class AppConsentConfirmationComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= govuk_panel(title_text: title, text: panel_text) %>

    <% if @consent_form.contact_injection %>
      <p>Someone will be in touch to discuss them having an injection instead.</p>
    <% end %>

    <p>We've sent a confirmation to <%= parent_email %></p>
  ERB

  def initialize(consent_form)
    super

    @consent_form = consent_form
  end

  def title
    if @consent_form.contact_injection
      "Your child will not get a nasal flu vaccination at school"
    else
      case @consent_form.response
      when "given"
        "Consent given"
      when "given_one"
        "Consent for the #{@consent_form.chosen_vaccine} vaccination confirmed"
      when "refused"
        "Consent refused"
      end
    end
  end

  private

  def panel_text
    case @consent_form.response
    when "given", "given_one"
      if @consent_form.needs_triage?
        <<-END_OF_TEXT
          As you answered ‘yes’ to some of the health questions, we need to check the
          #{vaccinations_are} suitable for #{patient_full_name}. We’ll review your
          answers and get in touch again soon.
        END_OF_TEXT
      else
        "#{patient_full_name} is due to get the #{vaccinations} at school on" \
          " #{session_dates}"
      end
    when "refused"
      "You’ve told us that you do not want #{patient_full_name} to get the" \
        " #{vaccinations} at school"
    end
  end

  def parent_email
    @consent_form.parent_email
  end

  def patient_full_name
    "#{@consent_form.given_name} #{@consent_form.family_name}"
  end

  def vaccines_key(programmes)
    programmes.map(&:type).sort.join("_")
  end

  def vaccinations
    vaccine_names =
      @consent_form.programmes.map do |programme|
        programme.type == "flu" ? "nasal flu" : programme.name
      end

    "#{vaccine_names.to_sentence} vaccination".pluralize(
      @consent_form.programmes.size
    )
  end

  def vaccinations_are
    "#{vaccinations} #{@consent_form.programmes.one? ? "is" : "are"}"
  end

  def session_dates
    @consent_form
      .location
      .sessions
      .strict_loading(false)
      .flat_map(&:dates)
      .map { it.to_fs(:short_day_of_week) }
      .to_sentence
  end
end
