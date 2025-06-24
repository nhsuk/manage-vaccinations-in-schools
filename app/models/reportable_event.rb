# == Schema Information
#
# Table name: reportable_events
#
#  id                                          :bigint           not null, primary key
#  event_timestamp                             :datetime
#  event_type                                  :string
#  gp_practice_address_postcode                :string
#  gp_practice_address_town                    :string
#  gp_practice_name                            :string
#  organisation_name                           :string
#  organisation_ods_code                       :string
#  patient_address_postcode                    :string
#  patient_address_town                        :string
#  patient_birth_academic_year                 :integer
#  patient_date_of_birth                       :date
#  patient_date_of_death                       :date
#  patient_gender_code                         :integer
#  patient_home_educated                       :boolean
#  patient_nhs_number                          :string
#  school_address_postcode                     :string
#  school_address_town                         :string
#  school_name                                 :string
#  source_type                                 :string
#  vaccination_record_delivery_method          :integer
#  vaccination_record_dose_sequence            :integer
#  vaccination_record_outcome                  :integer
#  vaccination_record_performed_at             :datetime
#  vaccination_record_performed_by_family_name :string
#  vaccination_record_performed_by_given_name  :string
#  vaccination_record_uuid                     :uuid
#  vaccine_brand                               :text
#  vaccine_discontinued                        :boolean          default(FALSE)
#  vaccine_dose_volume_ml                      :decimal(, )
#  vaccine_full_dose                           :boolean
#  vaccine_manufacturer                        :text
#  vaccine_method                              :integer
#  vaccine_nivs_name                           :text
#  vaccine_snomed_product_code                 :string
#  vaccine_snomed_product_term                 :string
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null
#  gp_practice_id                              :bigint
#  patient_id                                  :bigint
#  school_id                                   :bigint
#  source_id                                   :bigint
#  vaccination_record_batch_id                 :bigint
#  vaccination_record_performed_by_user_id     :bigint
#  vaccination_record_programme_id             :bigint
#  vaccination_record_session_id               :bigint
#  vaccine_id                                  :bigint
#  vaccine_programme_id                        :bigint
#
# Indexes
#
#  index_reportable_events_on_source  (source_type,source_id)
#
class ReportableEvent < ApplicationRecord
  
  def initialize(attrs={})
    references = attrs.to_h.select{ |_key,value| value.is_a?(ApplicationRecord)}
    simple_attrs = attrs.except(*references.keys)
    
    super( simple_attrs.to_h.select{ self.class.attribute_names.include?(it.to_s) } )

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
        send("#{this_attr_name}=", obj.attributes[key])
      end
    end
  end
end
