module ConsentFormsHelper
  def format_address(consent_form)
    safe_join(
      [
        consent_form.address_line_1,
        consent_form.address_line_2,
        consent_form.address_town,
        consent_form.address_postcode
      ].reject(&:blank?),
      tag.br
    )
  end

  def health_answer_response(health_answer)
    if health_answer.response == "yes"
      "Yes – #{health_answer.notes}"
    else
      "No"
    end
  end

  def previous_question_number(consent_form, health_answer)
    current_index =
      consent_form.each_health_answer.find_index do |ha|
        ha.id == health_answer.id
      end
    consent_form.each_health_answer.to_a[current_index - 1].id
  end

  def health_question_backlink_path(consent_form, health_answer)
    follow_up_changes_start_page = session[:follow_up_changes_start_page]&.to_i
    question_number = params[:question_number]&.to_i

    if follow_up_changes_start_page &&
         question_number == follow_up_changes_start_page
      wizard_path(Wicked::FINISH_STEP)
    elsif question_number&.positive?
      wizard_path(
        "health-question",
        question_number: previous_question_number(consent_form, health_answer)
      )
    else
      previous_wizard_path
    end
  end

  def backlink_path
    if params[:skip_to_confirm]
      wizard_path(Wicked::FINISH_STEP)
    else
      previous_wizard_path
    end
  end
end
