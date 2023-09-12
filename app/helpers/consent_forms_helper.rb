module ConsentFormsHelper
  def contact_method_for(consent_form)
    text = consent_form.human_enum_name(:contact_method)

    if consent_form.contact_method_other?
      "#{text} – #{consent_form.contact_method_other}"
    else
      text
    end
  end
end
