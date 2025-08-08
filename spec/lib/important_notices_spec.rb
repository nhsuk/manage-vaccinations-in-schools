# frozen_string_literal: true

describe ImportantNotices do
  shared_examples "generates notices" do
    context "when patient has no special status" do
      it { should be_empty }
    end

    context "when patient is deceased" do
      let(:recorded_at) { Date.new(2025, 2, 1) }

      before do
        patient.update!(
          date_of_death: Date.new(2025, 1, 1),
          date_of_death_recorded_at: recorded_at
        )
      end

      it "returns deceased notification" do
        expect(notices.count).to eq(1)
        expect(notices.first).to include(
          date_time: recorded_at,
          message: "Record updated with child’s date of death"
        )
      end
    end

    context "when patient is invalidated" do
      let(:invalidated_at) { Date.new(2025, 1, 1) }

      before { patient.update!(invalidated_at:) }

      it "returns invalidated notification" do
        expect(notices.count).to eq(1)
        expect(notices.first).to include(
          date_time: invalidated_at,
          message: "Record flagged as invalid"
        )
      end
    end

    context "when patient is restricted" do
      let(:restricted_at) { Date.new(2025, 1, 1) }

      before { patient.update!(restricted_at:) }

      it "returns restricted notification" do
        expect(notices.count).to eq(1)
        expect(notices.first).to include(
          date_time: restricted_at,
          message: "Record flagged as sensitive"
        )
      end
    end

    context "when patient has gillick no notify vaccination records" do
      let(:performed_at) { Date.new(2025, 1, 1) }

      let(:vaccination_record) do
        create(
          :vaccination_record,
          patient: patient,
          programme: programme,
          notify_parents: false,
          performed_at:
        )
      end

      before { vaccination_record }

      it "returns gillick no notify notification" do
        expect(notices.count).to eq(1)
        notification = notices.first
        expect(notification[:date_time]).to eq(performed_at)
        expect(notification[:message]).to include(
          "Child gave consent for HPV vaccination under Gillick competence"
        )
        expect(notification[:message]).to include(
          "does not want their parents to be notified"
        )
      end
    end

    context "when patient has multiple vaccination records with the same notify_parents values" do
      let(:other_programme) { create(:programme, :flu) }

      let(:notify_record) do
        create(
          :vaccination_record,
          patient:,
          programme: other_programme,
          notify_parents: false
        )
      end
      let(:no_notify_record) do
        create(:vaccination_record, patient:, programme:, notify_parents: false)
      end

      before do
        notify_record
        no_notify_record
      end

      it "only includes records with notify_parents false in the message" do
        expect(notices.count).to eq(1)
        expect(notices.first[:message]).to include("Flu and HPV vaccinations")
      end
    end

    context "when patient has multiple vaccination records with different notify_parents values" do
      let(:other_programme) { create(:programme, :flu) }

      let(:notify_record) do
        create(
          :vaccination_record,
          patient:,
          programme: other_programme,
          notify_parents: true
        )
      end
      let(:no_notify_record) do
        create(:vaccination_record, patient:, programme:, notify_parents: false)
      end

      before do
        notify_record
        no_notify_record
      end

      it "only includes records with notify_parents false in the message" do
        expect(notices.count).to eq(1)
        expect(notices.first[:message]).to include("HPV vaccination")
      end
    end

    context "when patient has multiple notification types" do
      let(:deceased_at) { Date.new(2025, 1, 3) }
      let(:restricted_at) { Date.new(2025, 1, 2) }
      let(:invalidated_at) { Date.new(2025, 1, 1) }

      before do
        patient.update!(
          date_of_death: Date.current,
          date_of_death_recorded_at: deceased_at,
          restricted_at: restricted_at,
          invalidated_at: invalidated_at
        )
      end

      it "returns all notices sorted by date_time descending" do
        expect(notices.count).to eq(3)

        # Should be sorted by date_time in reverse order (most recent first)
        expect(notices[0][:date_time]).to eq(deceased_at)
        expect(notices[1][:date_time]).to eq(restricted_at)
        expect(notices[2][:date_time]).to eq(invalidated_at)

        expect(notices[0][:message]).to include("date of death")
        expect(notices[1][:message]).to include("flagged as sensitive")
        expect(notices[2][:message]).to include("flagged as invalid")
      end
    end
  end

  let(:patient) { create(:patient) }
  let(:programme) { create(:programme, :hpv) }

  context "with a patient scope" do
    subject(:notices) { described_class.call(patient_scope:) }

    let(:patient_scope) { Patient.where(id: patient.id) }

    include_examples "generates notices"
  end

  context "with a single patient" do
    subject(:notices) do
      described_class.call(patient: patient_with_preloaded_associations)
    end

    let(:patient_with_preloaded_associations) do
      Patient.includes(vaccination_records: :programme).find(patient.id)
    end

    include_examples "generates notices"
  end
end
