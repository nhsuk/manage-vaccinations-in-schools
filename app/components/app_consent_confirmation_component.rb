# frozen_string_literal: true

class AppConsentConfirmationComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= govuk_panel(title_text: title, text: panel_text) %>

    <p>We've sent a confirmation to <%= parent_email %></p>
  ERB

  def initialize(consent_form)
    super

    @consent_form = consent_form
  end

  def title
    case response
    when "given"
      "Consent confirmed"
    when "given_one"
      chosen_programme = chosen_programmes.first.name
      "Consent for the #{chosen_programme} vaccination confirmed"
    when "refused"
      "Consent refused"
    else
      raise "unrecognised consent response: #{response}"
    end
  end

  private

  delegate :chosen_programmes,
           :not_chosen_programmes,
           :response,
           :parent_email,
           to: :@consent_form

  def full_name
    @consent_form.full_name(context: :parents)
  end

  def panel_text
    case response
    when "given", "given_one"
      if @consent_form.needs_triage?
        <<-END_OF_TEXT
          As you answered ‘yes’ to some of the health questions, we need to check
          the #{chosen_vaccinations_are} suitable for #{full_name}. We’ll review
          your answers and get in touch again soon.
        END_OF_TEXT
      else
        "#{full_name} is due to get the #{chosen_vaccinations} at school" +
          (session_dates.present? ? " on #{session_dates}" : "")
      end
    when "refused"
      "You’ve told us that you do not want #{full_name} to get the" \
        " #{not_chosen_vaccinations} at school"
    else
      raise "unrecognised consent response: #{response}"
    end
  end

  def chosen_vaccinations
    vaccinations_text(chosen_programmes)
  end

  def not_chosen_vaccinations
    vaccinations_text(not_chosen_programmes)
  end

  def vaccinations_text(programmes)
    programme_names =
      programmes.map do |programme|
        programme.type == "flu" ? "nasal flu" : programme.name
      end

    "#{programme_names.to_sentence} vaccination".pluralize(
      programme_names.count
    )
  end

  def chosen_vaccinations_are
    "#{chosen_vaccinations} #{chosen_programmes.one? ? "is" : "are"}"
  end

  def session_dates
    @consent_form
      .actual_session
      .today_or_future_dates
      .map { it.to_fs(:short_day_of_week) }
      .to_sentence(two_words_connector: " or ", last_word_connector: " or ")
  end
end
