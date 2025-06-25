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
      simple_attrs = attrs.except(*references.keys)
      
      # default initialization with simple values
      super( simple_attrs.to_h.select{ has_attribute?(it.to_sym) } )

      references.each_key do |name|
        copy_scoped_attributes(name, attrs[name])
      end
    end

    # given a prefix and object like :school, (School object)
    # copy each attribute from the given object to an attribute
    # on self, prefixed with the prefix
    # e.g. self.school_address_postcode = obj.postcode and so on
    def copy_scoped_attributes(prefix, obj)
      obj.attributes.each_key do |key|
        this_attr_name = [prefix, key].join('_')
        
        if has_attribute?(this_attr_name)
          self[this_attr_name] = obj.attributes[key]
        end
      end
    end
  end
end