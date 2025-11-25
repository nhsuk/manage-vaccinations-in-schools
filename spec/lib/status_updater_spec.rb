# frozen_string_literal: true

describe StatusUpdater do
  subject(:call) { described_class.call }

  around { |example| travel_to(Date.new(2025, 7, 31)) { example.run } }

  let(:session) { create(:session, programmes:) }

  before { create(:patient_location, patient:, session:) }

  context "with an HPV session and ineligible patient" do
    let(:programmes) { [Programme.hpv] }
    let(:patient) { create(:patient, year_group: 7) }

    it "doesn't create any consent statuses" do
      expect { call }.not_to change(Patient::ConsentStatus, :count)
    end

    it "creates a programme status for all programmes" do
      expect { call }.to change(patient.programme_statuses, :count).by(5)
      expect(patient.programme_statuses).to all(be_not_eligible)
    end

    it "doesn't create any registration statuses" do
      expect { call }.not_to change(Patient::RegistrationStatus, :count)
    end

    it "doesn't create any triage statuses" do
      expect { call }.not_to change(Patient::TriageStatus, :count)
    end

    it "doesn't create any vaccination statuses" do
      expect { call }.not_to change(Patient::VaccinationStatus, :count)
    end
  end

  context "with an flu session and eligible patient" do
    let(:programmes) { [Programme.flu] }
    let(:patient) { create(:patient, year_group: 8) }

    it "creates a consent status" do
      expect { call }.to change(patient.consent_statuses, :count).by(1)
      expect(patient.consent_statuses.first).to be_no_response
    end

    context "when consent is given" do
      before { create(:consent, patient:, programme: programmes.first) }

      it "sets the vaccine methods" do
        expect { call }.to change(patient.consent_statuses, :count).by(1)
        expect(patient.consent_statuses.first).to be_vaccine_method_injection
      end
    end

    it "creates a programme status for all programmes" do
      expect { call }.to change(patient.programme_statuses, :count).by(5)
    end

    it "creates a registration status" do
      expect { call }.to change(patient.registration_statuses, :count).by(1)
      expect(patient.registration_statuses.first).to be_unknown
    end

    it "creates a triage status" do
      expect { call }.to change(patient.triage_statuses, :count).by(1)
      expect(patient.triage_statuses.first).to be_not_required
    end

    it "creates a vaccination status" do
      expect { call }.to change(patient.vaccination_statuses, :count).by(1)
      expect(patient.vaccination_statuses.first).to be_eligible
    end
  end

  context "with an HPV session and eligible patient" do
    let(:programmes) { [Programme.hpv] }
    let(:patient) { create(:patient, year_group: 8) }

    it "creates a consent status" do
      expect { call }.to change(patient.consent_statuses, :count).by(1)
      expect(patient.consent_statuses.first).to be_no_response
    end

    it "creates a programme status for all programmes" do
      expect { call }.to change(patient.programme_statuses, :count).by(5)
    end

    it "creates a registration status" do
      expect { call }.to change(patient.registration_statuses, :count).by(1)
      expect(patient.registration_statuses.first).to be_unknown
    end

    it "creates a triage status" do
      expect { call }.to change(patient.triage_statuses, :count).by(1)
      expect(patient.triage_statuses.first).to be_not_required
    end

    it "creates a vaccination status" do
      expect { call }.to change(patient.vaccination_statuses, :count).by(1)
      expect(patient.vaccination_statuses.first).to be_eligible
    end
  end

  context "with a doubles session and ineligible patient" do
    let(:programmes) { [Programme.menacwy, Programme.td_ipv] }
    let(:patient) { create(:patient, year_group: 8) }

    it "doesn't create any consent statuses" do
      expect { call }.not_to change(Patient::ConsentStatus, :count)
    end

    it "creates a programme status for all programmes" do
      expect { call }.to change(patient.programme_statuses, :count).by(5)
    end

    it "doesn't create any registration statuses" do
      expect { call }.not_to change(Patient::RegistrationStatus, :count)
    end

    it "doesn't create any triage statuses" do
      expect { call }.not_to change(Patient::TriageStatus, :count)
    end

    it "doesn't create any vaccination statuses" do
      expect { call }.not_to change(Patient::VaccinationStatus, :count)
    end
  end

  context "with an doubles session and eligible patient" do
    let(:programmes) { [Programme.menacwy, Programme.td_ipv] }
    let(:patient) { create(:patient, year_group: 9) }

    it "creates a consent status for both programmes" do
      expect { call }.to change(patient.consent_statuses, :count).by(2)
      expect(patient.consent_statuses.first).to be_no_response
      expect(patient.consent_statuses.second).to be_no_response
    end

    it "creates a programme status for all programmes" do
      expect { call }.to change(patient.programme_statuses, :count).by(5)
    end

    it "creates a registration status" do
      expect { call }.to change(patient.registration_statuses, :count).by(1)
      expect(patient.registration_statuses.first).to be_unknown
    end

    it "creates a triage status for both programmes" do
      expect { call }.to change(patient.triage_statuses, :count).by(2)
      expect(patient.triage_statuses.first).to be_not_required
      expect(patient.triage_statuses.second).to be_not_required
    end

    it "creates a patient vaccination status for both programmes" do
      expect { call }.to change(patient.vaccination_statuses, :count).by(2)
      expect(patient.vaccination_statuses.first).to be_eligible
      expect(patient.vaccination_statuses.second).to be_eligible
    end
  end
end
