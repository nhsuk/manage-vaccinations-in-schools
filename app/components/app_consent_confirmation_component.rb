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
        chosen_programme = consented_programmes.first
        "Consent for the #{chosen_programme.name} vaccination confirmed"
      when "refused"
        "Consent refused"
      else
        raise "unrecognised consent response: #{@consent_form.response}"
      end
    end
  end

  private

  def panel_text
    case @consent_form.response
    when "given", "given_one"
      if @consent_form.needs_triage?
        <<-END_OF_TEXT
          As you answered ‘yes’ to some of the health questions, we need to check
          the #{vaccinations_are} suitable for #{patient_full_name}. We’ll review
          your answers and get in touch again soon.
        END_OF_TEXT
      else
        "#{patient_full_name} is due to get the #{vaccinations} at school on" \
          " #{session_dates}"
      end
    when "refused"
      "You’ve told us that you do not want #{patient_full_name} to get the" \
        " #{refused_programmes.first.name} vaccination at school"
    else
      raise "unrecognised consent response: #{@consent_form.response}"
    end
  end

  def parent_email
    @consent_form.parent_email
  end

  def patient_full_name
    "#{@consent_form.given_name} #{@consent_form.family_name}"
  end

  def consented_programmes
    @consented_programmes ||=
      case @consent_form.response
      when "given"
        @consent_form.programmes
      when "given_one"
        [@consent_form.programmes.find_by(type: @consent_form.chosen_vaccine)]
      else
        []
      end
  end

  def refused_programmes
    @consent_form.programmes - consented_programmes
  end

  def vaccinations(programmes: consented_programmes)
    programme_names =
      programmes.map do |programme|
        programme.type == "flu" ? "nasal flu" : programme.name
      end

    "#{programme_names.to_sentence} vaccination".pluralize(
      programme_names.count
    )
  end

  def refused_vaccinations
    vaccinations(programmes: refused_programmes)
  end

  def vaccinations_are
    "#{vaccinations} #{consented_programmes.one? ? "is" : "are"}"
  end

  def session_dates
    @consent_form
      .location
      .sessions
      .includes(:session_dates)
      .flat_map(&:dates)
      .map { it.to_fs(:short_day_of_week) }
      .to_sentence
  end
end
