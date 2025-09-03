# frozen_string_literal: true

# Convenience methods for initializing an instance of the including class
# with a mix of simple-valued attributes (e.g. {name: 'a name', thing_id: 123} )
# and named objects (e.g. patient: (instance of Patient) ).
# This enables attributes to be copied from the given objects to the corresponding
# scoped attributes on the model
# Example:
#  `obj = (class).new( name: 'my name', thing_id: 123, patient: (instance of patient) )`
#  results in obj getting these attributes:
#  ```
#  name = 'my name',
#  thing_id = 123,
#  patient_id = (id of patient instance)
#  patient_address_postcode = (postcode from patient instance)
#  patient_given_name = (given_name of patient instance)
#  ````
#  ...etc
module ReportingAPI::DenormalizingConcern
  extend ActiveSupport::Concern

  included do
    def initialize(attrs = {})
      attrs = attrs.to_h
      references = attrs.select { |_, v| v.is_a?(ApplicationRecord) }
      copy_attributes_from_references(references)

      simple_valued_attrs = attrs.except(*references.keys)
      super(**entries_which_exist_in_attributes(simple_valued_attrs))
    end

    def copy_attributes_from_references(references = {})
      attr_set = self.class.attribute_names.to_set

      references.each do |name, record|
        if record
          copy_scoped_attributes(name, record, attr_set)
        else
          attr_set.grep(/^#{name}_/).each { |k| self[k] = nil }
        end
      end
    end

    protected

    # given a hash, return only the keys which exist in this class' attributes
    def entries_which_exist_in_attributes(attrs = {})
      attrs.slice(*self.class.attribute_names.map(&:to_sym)).symbolize_keys
    end

    # given a prefix and object like :school, (School object)
    # copy each attribute from the given object to an attribute
    # on self, prefixed with the prefix
    # e.g. self.school_address_postcode = obj.postcode and so on
    def copy_scoped_attributes(
      prefix,
      record,
      attr_set = self.class.attribute_names.to_set
    )
      record.attributes&.each do |key, value|
        attr_name = "#{prefix}_#{key}"
        self[attr_name] = value if attr_set.include?(attr_name)
      end
    end
  end
end
