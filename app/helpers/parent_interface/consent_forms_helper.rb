# frozen_string_literal: true

module ParentInterface::ConsentFormsHelper
  def vaccines_key(programmes)
    programmes.map(&:type).sort.join("_")
  end

  def programme_names_text(programmes)
    "#{programmes.map(&:name).to_sentence} vaccination".pluralize(
      programmes.size
    )
  end
end
