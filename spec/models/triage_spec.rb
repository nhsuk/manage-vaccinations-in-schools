# frozen_string_literal: true

# == Schema Information
#
# Table name: triage
#
#  id                   :bigint           not null, primary key
#  notes                :text             default(""), not null
#  status               :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  organisation_id      :bigint           not null
#  patient_id           :bigint           not null
#  performed_by_user_id :bigint           not null
#  programme_id         :bigint           not null
#
# Indexes
#
#  index_triage_on_organisation_id       (organisation_id)
#  index_triage_on_patient_id            (patient_id)
#  index_triage_on_performed_by_user_id  (performed_by_user_id)
#  index_triage_on_programme_id          (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#

describe Triage do
  subject(:triage) { create(:triage) }

  describe "validations" do
    it { should_not validate_presence_of(:notes) }
    it { should validate_length_of(:notes).is_at_most(1000) }
  end

  describe "#process!" do
    subject(:process!) { triage.process! }

    let(:programme) { create(:programme) }
    let(:organisation) { create(:organisation, programmes: [programme]) }
    let(:triage) { create(:triage, status, organisation:, programme:) }

    context "when ready to vaccinate" do
      let(:status) { :ready_to_vaccinate }

      it "doesn't create any patient sessions" do
        expect { process! }.not_to change(PatientSession, :count)
      end
    end

    context "when do not vaccinate" do
      let(:status) { :do_not_vaccinate }

      it "doesn't create any patient sessions" do
        expect { process! }.not_to change(PatientSession, :count)
      end
    end

    context "when needs follow up" do
      let(:status) { :needs_follow_up }

      it "doesn't create any patient sessions" do
        expect { process! }.not_to change(PatientSession, :count)
      end
    end

    context "when delay vaccination" do
      let(:status) { :delay_vaccination }

      it "adds the patient to the generic clinic" do
        expect { process! }.to change(
          triage.patient.upcoming_sessions,
          :count
        ).by(1)

        expect(
          triage.patient.upcoming_sessions.last.location
        ).to be_generic_clinic
      end
    end
  end
end
