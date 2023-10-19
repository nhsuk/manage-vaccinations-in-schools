class PostcodeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    ukpc = UKPostcode.parse(value.to_s)
    unless ukpc.full_valid?
      record.errors.add(attribute, "Enter a valid postcode")
    end
  end
end
