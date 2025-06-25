require 'spec_helper'

class DummyClass
  include ActiveModel::Model
  include DenormalizingConcern
  
  attr_accessor :patient_nhs_number, :patient_date_of_birth, :patient_date_of_death, :school_name, 
                :school_address_postcode
      
  def self.attribute_names
    %w[ patient_nhs_number
        patient_date_of_birth 
        patient_date_of_death 
        school_name 
        school_address_postcode
      ]
  end

  def has_attribute?(attr)
    self.class.attribute_names.include?(attr.to_sym)
  end

  def [](attr)
    send(attr)
  end

  def []=(attr, val)
    send("#{attr}=", val)
  end
end
RSpec.describe DenormalizingConcern do
  describe '#initialize' do
    context 'given some attributes' do
      subject(:instance){ DummyClass.new(attrs) }

      context 'which are simple values' do
        let(:attrs) do 
          {
            patient_nhs_number: '12345678',
            school_name: 'Headlands Comprehensive',
            patient_date_of_death: '2021-01-02'.to_date,
          }
        end

        it 'copies the given attribute values to the corresponding attribute' do
          expect(instance).to have_attributes(attrs)
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
          expect(instance).to have_attributes(
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
          expect{ DummyClass.new(attrs) }.not_to raise_error
        end
      end
    end
  end

  describe '#copy_attributes_from_references' do
    context 'when an instance already has scoped attributes populated' do
      subject(:instance){ DummyClass.new(attrs) }

      let(:patient) { build(:patient, date_of_birth: '2018-02-03'.to_date, date_of_death: '2022-03-04'.to_date) }
      let(:attrs) do
        {
          patient: patient,
        }
      end

      describe 'passing the scope with a nil value' do
        it 'sets all attributes starting with that scope to nil' do
          instance.copy_attributes_from_references( patient: nil )
          expect( instance ).to have_attributes( patient_date_of_birth: nil, patient_date_of_death: nil )
        end
      end
    end
  end
end