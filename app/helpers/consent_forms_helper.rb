module ConsentFormsHelper
  def contact_method_for(consent_form)
    text = consent_form.human_enum_name(:contact_method)

    if consent_form.contact_method_other?
      "#{text} – #{consent_form.contact_method_other}"
    else
      text
    end
  end

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
end
