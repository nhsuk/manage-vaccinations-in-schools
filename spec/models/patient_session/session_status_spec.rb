# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_session_session_statuses
#
#  id                 :bigint           not null, primary key
#  status             :integer          default("none_yet"), not null
#  patient_session_id :bigint           not null
#  programme_id       :bigint           not null
#
# Indexes
#
#  idx_on_patient_session_id_programme_id_8777f5ba39  (patient_session_id,programme_id) UNIQUE
#  index_patient_session_session_statuses_on_status   (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
describe PatientSession::SessionStatus do
  subject(:patient_session_session_status) do
    build(:patient_session_session_status, patient_session:, programme:)
  end

  let(:patient_session) { create(:patient_session, programmes: [programme]) }
  let(:programme) { create(:programme) }

  it { should belong_to(:patient_session) }
  it { should belong_to(:programme) }

  it do
    expect(patient_session_session_status).to define_enum_for(
      :status
    ).with_values(
      %i[
        none_yet
        vaccinated
        already_had
        had_contraindications
        refused
        absent_from_session
        unwell
      ]
    )
  end

  describe "#status" do
    subject(:status) { patient_session_session_status.assign_status }

    let(:patient) { patient_session.patient }
    let(:session) { patient_session.session }

    context "with no vaccination record" do
      it { should be(:none_yet) }
    end

    context "with a vaccination administered" do
      before { create(:vaccination_record, patient:, session:, programme:) }

      it { should be(:vaccinated) }
    end

    context "with a vaccination not administered" do
      before do
        create(
          :vaccination_record,
          :not_administered,
          patient:,
          session:,
          programme:
        )
      end

      it { should be(:unwell) }
    end

    context "with a discarded vaccination administered" do
      before do
        create(:vaccination_record, :discarded, patient:, session:, programme:)
      end

      it { should be(:none_yet) }
    end

    context "with a consent refused" do
      before { create(:consent, :refused, patient:, programme:) }

      it { should be(:refused) }
    end

    context "with conflicting consent" do
      before do
        create(:consent, :refused, patient:, programme:)

        parent = create(:parent_relationship, patient:).parent
        create(:consent, :given, patient:, programme:, parent:)
      end

      it { should be(:none_yet) }
    end

    context "when triaged as do not vaccinate" do
      before { create(:triage, :do_not_vaccinate, patient:, programme:) }

      it { should be(:had_contraindications) }
    end

    context "when not attending the session" do
      before { create(:session_attendance, :absent, patient_session:) }

      it { should be(:absent_from_session) }
    end
  end
end
