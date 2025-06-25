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
module DenormalizingConcern
  extend ActiveSupport::Concern

  included do
    def initialize(attrs={})
      references = attrs.to_h.select{ |_key,value| value.is_a?(ApplicationRecord)}
      copy_attributes_from_references(references)

      simple_attrs = attrs.to_h.except(*references.keys)
      
      super( simple_attrs.to_h.select { self.class.attribute_names.include?(it.to_s) } )
    end

    def copy_attributes_from_references(references={})
      references.each_key do |name|
        if references[name]
          copy_scoped_attributes(name, references[name])
        else
          self.class.attribute_names.select{|k,v| k.start_with?(name.to_s + '_')}.each{|k| self[k] = nil }
        end
      end
    end

    # given a prefix and object like :school, (School object)
    # copy each attribute from the given object to an attribute
    # on self, prefixed with the prefix
    # e.g. self.school_address_postcode = obj.postcode and so on
    def copy_scoped_attributes(prefix, obj)
      obj.attributes&.each_key do |key|
        this_attr_name = [prefix, key].join('_')
        
        if self.class.attribute_names.include?(this_attr_name.to_s)
          self[this_attr_name] = obj.attributes[key]
        end
      end
    end
  end
end