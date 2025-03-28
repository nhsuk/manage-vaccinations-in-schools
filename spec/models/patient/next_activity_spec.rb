# frozen_string_literal: true

describe Patient::NextActivity do
  subject(:instance) { described_class.new(patient) }

  let(:programme) { create(:programme, :hpv) }
  let(:patient) { create(:patient, year_group: 8) }

  before { patient.strict_loading!(false) }

  describe "#status" do
    subject(:status) { instance.status[programme] }

    context "with no consent" do
      it { should be(described_class::CONSENT) }
    end

    context "with consent refused" do
      before { create(:patient_consent_status, :refused, patient:, programme:) }

      it { should be(described_class::DO_NOT_RECORD) }
    end

    context "with triaged as do not vaccinate" do
      before do
        create(:patient_consent_status, :given, patient:, programme:)
        create(:patient_triage_status, :do_not_vaccinate, patient:, programme:)
      end

      it { should be(described_class::DO_NOT_RECORD) }
    end

    context "with consent needing triage" do
      before do
        create(:patient_consent_status, :given, patient:, programme:)
        create(:patient_triage_status, :required, patient:, programme:)
      end

      it { should be(described_class::TRIAGE) }
    end

    context "with triaged as safe to vaccinate" do
      before do
        create(:patient_consent_status, :given, patient:, programme:)
        create(:patient_triage_status, :safe_to_vaccinate, patient:, programme:)
      end

      it { should be(described_class::RECORD) }
    end

    context "with consent no triage needed" do
      before { create(:patient_consent_status, :given, patient:, programme:) }

      it { should be(described_class::RECORD) }
    end

    context "with an administered vaccination record" do
      before do
        create(:patient_consent_status, :given, patient:, programme:)
        create(:vaccination_record, patient:, programme:)
      end

      it { should be(described_class::REPORT) }
    end

    context "with an already had administered vaccination record" do
      before do
        create(:patient_consent_status, :given, patient:, programme:)
        create(
          :vaccination_record,
          :not_administered,
          :already_had,
          patient:,
          programme:
        )
      end

      it { should be(described_class::REPORT) }
    end

    context "with an un-administered vaccination record" do
      before do
        create(:patient_consent_status, :given, patient:, programme:)
        create(:vaccination_record, :not_administered, patient:, programme:)
      end

      it { should be(described_class::RECORD) }
    end
  end
end
