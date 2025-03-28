# frozen_string_literal: true

describe StatusUpdater do
  subject(:call) { described_class.call }

  before { create(:patient_session, patient:, programmes:) }

  context "with an HPV session and ineligible patient" do
    let(:programmes) { [create(:programme, :hpv)] }
    let(:patient) { create(:patient, year_group: 7) }

    it "doesn't create any consent statuses" do
      expect { call }.not_to change(Patient::ConsentStatus, :count)
    end
  end

  context "with an HPV session and eligible patient" do
    let(:programmes) { [create(:programme, :hpv)] }
    let(:patient) { create(:patient, year_group: 8) }

    it "creates a consent statuses" do
      expect { call }.to change(patient.consent_statuses, :count).by(1)
      expect(patient.consent_statuses.first).to be_no_response
    end
  end

  context "with a doubles session and ineligible patient" do
    let(:programmes) do
      [create(:programme, :menacwy), create(:programme, :td_ipv)]
    end
    let(:patient) { create(:patient, year_group: 8) }

    it "doesn't create any consent statuses" do
      expect { call }.not_to change(Patient::ConsentStatus, :count)
    end
  end

  context "with an doubles session and eligible patient" do
    let(:programmes) do
      [create(:programme, :menacwy), create(:programme, :td_ipv)]
    end
    let(:patient) { create(:patient, year_group: 9) }

    it "creates a consent status for both programmes" do
      expect { call }.to change(patient.consent_statuses, :count).by(2)
      expect(patient.consent_statuses.first).to be_no_response
      expect(patient.consent_statuses.second).to be_no_response
    end
  end
end
