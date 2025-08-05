# frozen_string_literal: true

describe PatientsHelper do
  describe "#patient_nhs_number" do
    subject(:patient_nhs_number) { helper.patient_nhs_number(patient) }

    context "when the NHS number is present" do
      let(:patient) { build(:patient, nhs_number: "0123456789") }

      it { should be_html_safe }

      it do
        expect(patient_nhs_number).to eq(
          "<span class=\"app-u-monospace nhsuk-u-nowrap\">012 345 6789</span>"
        )
      end

      context "when the patient is invalidated" do
        let(:patient) do
          build(:patient, :invalidated, nhs_number: "0123456789")
        end

        it { should be_html_safe }

        it do
          expect(patient_nhs_number).to eq(
            "<s><span class=\"app-u-monospace nhsuk-u-nowrap\">012 345 6789</span></s>"
          )
        end
      end
    end

    context "when the NHS number is not present" do
      let(:patient) { build(:patient, nhs_number: nil) }

      it { should_not be_html_safe }
      it { should eq("Not provided") }

      context "when the patient is invalidated" do
        let(:patient) { build(:patient, :invalidated, nhs_number: nil) }

        it { should be_html_safe }

        it { expect(patient_nhs_number).to eq("<s>Not provided</s>") }
      end
    end
  end

  describe "#patient_date_of_birth" do
    subject(:patient_date_of_birth) do
      travel_to(today) { helper.patient_date_of_birth(patient) }
    end

    let(:patient) { create(:patient, date_of_birth: Date.new(2000, 1, 1)) }
    let(:today) { Date.new(2024, 1, 1) }

    it { should eq("1 January 2000 (aged 24)") }
  end

  describe "#patient_school" do
    subject(:patient_school) { helper.patient_school(patient) }

    context "without a school" do
      let(:patient) { create(:patient) }

      it { should eq("Unknown school") }
    end

    context "with a school" do
      let(:school) { create(:school, name: "Waterloo Road") }
      let(:patient) { create(:patient, school:) }

      it { should eq("Waterloo Road") }
    end

    context "when home educated" do
      let(:patient) { create(:patient, :home_educated) }

      it { should eq("Home-schooled") }
    end
  end

  describe "#patient_year_group" do
    subject do
      travel_to(today) { helper.patient_year_group(patient, academic_year:) }
    end

    let(:patient) do
      create(:patient, date_of_birth: Date.new(2010, 1, 1), registration: nil)
    end

    let(:today) { Date.new(2024, 1, 1) }

    context "in the current academic year" do
      let(:academic_year) { today.academic_year }

      it { should eq("Year 9") }

      context "with a registration" do
        before do
          patient.registration = "9AB"
          patient.registration_academic_year = today.academic_year
        end

        it { should eq("Year 9 (9AB)") }
      end
    end

    context "in the next academic year" do
      let(:academic_year) { today.academic_year + 1 }

      it { should eq("Year 10 (2024 to 2025 academic year)") }

      context "with a registration" do
        before do
          patient.registration = "9AB"
          patient.registration_academic_year = today.academic_year
        end

        it { should eq("Year 10 (2024 to 2025 academic year)") }
      end
    end
  end

  describe "patient_important_notices" do
    subject(:notifications) { helper.patient_important_notices(patient) }

    let(:patient) { create(:patient) }
    let(:programme) { create(:programme, :hpv) }

    context "when patient has no special status" do
      it "returns empty array" do
        expect(notifications).to eq([])
      end
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
        expect(notifications.count).to eq(1)
        expect(notifications.first).to include(
          date_time: recorded_at,
          message: "Record updated with child’s date of death"
        )
      end
    end

    context "when patient is invalidated" do
      let(:invalidated_at) { Date.new(2025, 1, 1) }

      before { patient.update!(invalidated_at:) }

      it "returns invalidated notification" do
        expect(notifications.count).to eq(1)
        expect(notifications.first).to include(
          date_time: invalidated_at,
          message: "Record flagged as invalid"
        )
      end
    end

    context "when patient is restricted" do
      let(:restricted_at) { Date.new(2025, 1, 1) }

      before { patient.update!(restricted_at:) }

      it "returns restricted notification" do
        expect(notifications.count).to eq(1)
        expect(notifications.first).to include(
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
        expect(notifications.count).to eq(1)
        notification = notifications.first
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
        expect(notifications.count).to eq(1)
        expect(notifications.first[:message]).to include(
          "Flu and HPV vaccinations"
        )
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
        expect(notifications.count).to eq(1)
        expect(notifications.first[:message]).to include("HPV vaccination")
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

      it "returns all notifications sorted by date_time descending" do
        expect(notifications.count).to eq(3)

        # Should be sorted by date_time in reverse order (most recent first)
        expect(notifications[0][:date_time]).to eq(deceased_at)
        expect(notifications[1][:date_time]).to eq(restricted_at)
        expect(notifications[2][:date_time]).to eq(invalidated_at)

        expect(notifications[0][:message]).to include("date of death")
        expect(notifications[1][:message]).to include("flagged as sensitive")
        expect(notifications[2][:message]).to include("flagged as invalid")
      end
    end
  end
end
