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
require 'spec_helper'

RSpec.describe ReportableEvent do

  describe '#initialize' do
    context 'given some attributes' do
      subject{ described_class.new(attrs) }

      context 'which are simple values' do
        let(:attrs) do 
          {
            patient_nhs_number: '12345678',
            school_name: 'Headlands Comprehensive',
            patient_date_of_death: '2021-01-02'.to_date,
          }
        end

        it 'copies the given attribute values to the corresponding attribute' do
          expect(subject).to have_attributes(attrs)
        end
      end

      context 'which are ApplicationRecord instances' do
        let(:patient) { build(:patient, date_of_birth: '2018-02-03'.to_date, date_of_death: '2022-03-04'.to_date) }
        let(:school) { build(:school) }

        let(:attrs) do 
          {
            patient: patient,
            school: school,
          }
        end

        it 'copies the given instances attributes to the corresponding prefixed attributes' do
          expect(subject).to have_attributes(
            {
              patient_date_of_birth: '2018-02-03'.to_date, 
              patient_date_of_death: '2022-03-04'.to_date,
              school_name: school.name,
              school_address_postcode: school.address_postcode,
            }
          )
        end
      end

      context 'which do not exist in the ReportableEvent attributes' do
        let(:attrs) do
          {
            unknown_attribute_name: 'some value'
          }
        end

        it 'does not raise an error' do
          expect{ described_class.new(attrs) }.not_to raise_error
        end
      end
    end
  end
end
