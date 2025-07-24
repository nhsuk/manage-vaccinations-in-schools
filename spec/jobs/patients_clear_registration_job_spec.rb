# frozen_string_literal: true

describe PatientsClearRegistrationJob do
  subject(:perform) { described_class.new.perform }

  around { |example| travel_to(today) { example.run } }

  let(:patient_with_known_academic_year) do
    create(:patient, registration: "ABC", registration_academic_year: 2024)
  end
  let(:patient_with_unknown_academic_year) do
    create(:patient, registration: "ABC", registration_academic_year: nil)
  end

  context "on the last day of July" do
    let(:today) { Date.new(2025, 7, 31) }

    it "doesn't clear the patient with a known academic year" do
      expect { perform }.not_to(
        change { patient_with_known_academic_year.reload.registration }
      )
    end

    it "clears the patient with an unknown academic year" do
      expect { perform }.to change {
        patient_with_unknown_academic_year.reload.registration
      }.to(nil)
    end
  end

  context "on the first day of August" do
    let(:today) { Date.new(2025, 8, 1) }

    it "clears the patient with a known academic" do
      expect { perform }.to change {
        patient_with_known_academic_year.reload.registration
      }.to(nil).and change(patient_with_known_academic_year, :registration_academic_year).to(nil)
    end

    it "clears the patient with an unknown academic year" do
      expect { perform }.to change {
        patient_with_unknown_academic_year.reload.registration
      }.to(nil)
    end
  end
end
