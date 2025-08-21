# frozen_string_literal: true

class ClassIncludingConcern
  attr_accessor :patient, :patient_year_group, :source, :event_timestamp, :event_timestamp_day, :event_timestamp_month, :event_timestamp_year
  include ActiveModel::Model

  def self.belongs_to(*args, **kwargs); end

  def self.before_validation(*hooks)
    @before_validation_hooks ||= []
    @before_validation_hooks += hooks
  end

  include ReportingAPI::EventConcern
end

describe ReportingAPI::EventConcern do
  subject(:object_including_the_concern) { ClassIncludingConcern.new }

  describe '#set_patient_from_source' do
    let(:patient) { Patient.new }
    let(:source) { Consent.new(patient: patient) }

    context "when there is a source with a patient" do
      before do
        object_including_the_concern.source = source
      end

      it "sets the patient on the object to match" do
        expect { object_including_the_concern.send(:set_patient_from_source) }.to change(object_including_the_concern, :patient).to source.patient
      end
    end

    context "when the source is nil" do
      before do
        object_including_the_concern.source = nil
      end

      it "sets the patient on the object to nil" do
        object_including_the_concern.send(:set_patient_from_source)
        expect(object_including_the_concern.patient).to be_nil
      end
    end

    context "when the source does not have a patient method" do
      before do
        object_including_the_concern.source = LocalAuthority.new
      end

      it "does not raise an exception" do
        expect{ object_including_the_concern.send(:set_patient_from_source) }.not_to raise_error
      end

      it "sets the patient on the object to nil" do
        object_including_the_concern.send(:set_patient_from_source)
        expect(object_including_the_concern.patient).to be_nil
      end
    end
  end

  describe "#set_patient_year_group" do
    context "when the object has an event_timestamp" do
      before do
        object_including_the_concern.event_timestamp = Date.new(2025, 5, 12)
      end
      
      context "and a patient" do
        before do
          object_including_the_concern.patient = Patient.new(date_of_birth: Date.new(2014, 7, 21), birth_academic_year: 2013 )
        end

        it "sets the patient_year_group to be the year group of the patient at the date of the event_timestamp" do
          expect{ object_including_the_concern.send(:set_patient_year_group) }.to change(object_including_the_concern, :patient_year_group).to(6)
        end
      end

      context "but no patient" do
        before do
          object_including_the_concern.patient_year_group = 6
          object_including_the_concern.patient = nil
        end

        it "sets the patient_year_group to nil" do
          expect{ object_including_the_concern.send(:set_patient_year_group) }.to change(object_including_the_concern, :patient_year_group).to(nil)
        end
      end
    end

    context "when the object does not have an event_timestamp" do
      before do
        object_including_the_concern.patient_year_group = 6
        object_including_the_concern.event_timestamp = nil
      end

      it "sets the patient_year_group to nil" do
        expect{ object_including_the_concern.send(:set_patient_year_group) }.to change(object_including_the_concern, :patient_year_group).to(nil)
      end
    end
  end
end