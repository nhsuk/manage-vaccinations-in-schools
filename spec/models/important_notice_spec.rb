# frozen_string_literal: true

# == Schema Information
#
# Table name: important_notices
#
#  id                    :bigint           not null, primary key
#  can_dismiss           :boolean          default(FALSE)
#  date_time             :datetime
#  dismissed_at          :datetime
#  message               :text
#  notice_type           :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  dismissed_by_user_id  :bigint
#  patient_id            :bigint           not null
#  team_id               :bigint           not null
#  vaccination_record_id :bigint
#
# Indexes
#
#  index_important_notices_on_dismissed_by_user_id          (dismissed_by_user_id)
#  index_important_notices_on_patient_id                    (patient_id)
#  index_important_notices_on_team_id                       (team_id)
#  index_important_notices_on_vaccination_record_id         (vaccination_record_id)
#  index_notices_on_patient_and_type_and_datetime_and_team  (patient_id,notice_type,date_time,team_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (dismissed_by_user_id => users.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (vaccination_record_id => vaccination_records.id)
#
describe ImportantNotice do
  subject(:notice) { build(:important_notice) }

  let(:team) { create(:team) }
  let(:patient) { create(:patient) }
  let(:user) { create(:user) }

  describe "validations" do
    it { should validate_presence_of(:notice_type) }
    it { should validate_presence_of(:date_time) }
    it { should validate_presence_of(:message) }
  end

  describe "associations" do
    it { should belong_to(:patient) }
  end

  describe "enums" do
    it do
      expect(notice).to define_enum_for(:notice_type).with_values(
        deceased: 0,
        invalidated: 1,
        restricted: 2,
        gillick_no_notify: 3
      )
    end
  end

  describe ".latest_for_patient" do
    context "when patient has no special status" do
      it "returns empty array" do
        expect(described_class.latest_for_patient(patient:)).to be_empty
      end
    end

    context "when patient is deceased" do
      before { patient.update!(date_of_death: Date.current) }

      let!(:deceased_notice) do
        create(
          :important_notice,
          patient:,
          notice_type: :deceased,
          team_id: team.id
        )
      end

      it "returns deceased notice" do
        results = described_class.latest_for_patient(patient:)
        expect(results).to contain_exactly(deceased_notice)
      end
    end

    context "when patient is restricted" do
      let(:old_restricted_notice) do
        create(
          :important_notice,
          patient:,
          notice_type: :restricted,
          date_time: 2.days.ago
        )
      end
      let(:new_restricted_notice) do
        create(
          :important_notice,
          patient:,
          notice_type: :restricted,
          date_time: 1.day.ago
        )
      end

      before do
        old_restricted_notice
        new_restricted_notice
        patient.update!(restricted_at: 1.day.ago)
      end

      it "returns only the latest restricted notice" do
        results = described_class.latest_for_patient(patient:)
        expect(results).to contain_exactly(new_restricted_notice)
      end
    end

    context "when patient is not restricted" do
      let(:restricted_notice) do
        create(:important_notice, patient:, notice_type: :restricted)
      end

      it "does not return restricted notice" do
        results = described_class.latest_for_patient(patient:)
        expect(results).to be_empty
      end
    end

    context "when patient is invalidated" do
      let(:old_invalidated_notice) do
        create(
          :important_notice,
          team_id: team.id,
          patient:,
          notice_type: :invalidated,
          date_time: 2.days.ago
        )
      end
      let(:new_invalidated_notice) do
        create(
          :important_notice,
          team_id: team.id,
          patient:,
          notice_type: :invalidated,
          date_time: 1.day.ago
        )
      end

      before do
        old_invalidated_notice
        new_invalidated_notice
        patient.update!(invalidated_at: 1.day.ago)
      end

      it "returns only the latest invalidated notice" do
        results = described_class.latest_for_patient(patient:)
        expect(results).to contain_exactly(new_invalidated_notice)
      end
    end

    context "when patient is not invalidated" do
      let(:invalidated_notice) do
        create(:important_notice, patient:, notice_type: :invalidated)
      end

      it "does not return invalidated notice" do
        results = described_class.latest_for_patient(patient:)
        expect(results).to be_empty
      end
    end

    context "when patient has gillick consent notices" do
      let!(:gillick_notice_one) do
        create(:important_notice, patient:, notice_type: :gillick_no_notify)
      end
      let!(:gillick_notice_two) do
        create(:important_notice, patient:, notice_type: :gillick_no_notify)
      end

      it "returns all gillick consent notices" do
        results = described_class.latest_for_patient(patient:)
        expect(results).to contain_exactly(
          gillick_notice_one,
          gillick_notice_two
        )
      end
    end

    context "when patient has multiple notice types" do
      let(:deceased_notice) do
        create(:important_notice, patient:, notice_type: :deceased)
      end
      let(:old_restricted_notice) do
        create(
          :important_notice,
          patient:,
          notice_type: :restricted,
          date_time: 3.days.ago
        )
      end
      let(:new_restricted_notice) do
        create(
          :important_notice,
          patient:,
          notice_type: :restricted,
          date_time: 1.day.ago
        )
      end
      let(:old_invalidated_notice) do
        create(
          :important_notice,
          patient:,
          notice_type: :invalidated,
          date_time: 4.days.ago
        )
      end
      let(:new_invalidated_notice) do
        create(
          :important_notice,
          patient:,
          notice_type: :invalidated,
          date_time: 2.days.ago
        )
      end
      let(:gillick_notice) do
        create(:important_notice, patient:, notice_type: :gillick_no_notify)
      end

      before do
        patient.update!(
          date_of_death: Date.current,
          restricted_at: 1.day.ago,
          invalidated_at: 1.day.ago
        )
        old_restricted_notice
        new_restricted_notice
        old_invalidated_notice
        new_invalidated_notice
        deceased_notice
        gillick_notice
      end

      it "returns latest restricted/invalidated and all deceased/gillick notices" do
        results = described_class.latest_for_patient(patient:)
        expect(results).to contain_exactly(
          new_restricted_notice,
          new_invalidated_notice,
          deceased_notice,
          gillick_notice
        )
      end
    end
  end

  describe "#dismiss!" do
    let(:notice) { create(:important_notice, team_id: team.id) }

    context "when dismissing without a user" do
      it "sets dismissed_at" do
        freeze_time do
          notice.dismiss!
          expect(notice.dismissed_at).to eq(Time.current)
        end
      end

      it "does not set dismissed_by_user_id" do
        notice.dismiss!
        expect(notice.dismissed_by_user_id).to be_nil
      end
    end

    context "when dismissing with a user" do
      it "sets dismissed_at and dismissed_by_user_id" do
        freeze_time do
          notice.dismiss!(user: user)
          expect(notice.dismissed_at).to eq(Time.current)
          expect(notice.dismissed_by_user_id).to eq(user.id)
        end
      end
    end
  end
end
