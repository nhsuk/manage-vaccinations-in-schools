# frozen_string_literal: true

describe ConsentRequestsSessionBatchJob, type: :job do
  before { ActionMailer::Base.deliveries.clear }

  let(:parents_of_patient_without_consent_sent) { create_list(:parent, 2) }

  it "only sends emails to patient's parents to whom they have not been sent yet" do
    patient_with_consent_sent =
      create(:patient, sent_consent_at: Time.zone.today)
    patient_not_sent_consent =
      create(:patient, parents: parents_of_patient_without_consent_sent)
    session =
      create(
        :session,
        patients: [patient_with_consent_sent, patient_not_sent_consent]
      )

    expect { described_class.perform_now(session) }.to send_email(
      to: parents_of_patient_without_consent_sent.first.email
    ).and send_email(to: parents_of_patient_without_consent_sent.second.email)

    expect(ActionMailer::Base.deliveries.count).to eq(2)
  end

  it "updates the sent_consent_at attribute for patients" do
    patient = create(:patient, sent_consent_at: nil)
    session = create(:session, patients: [patient])

    described_class.perform_now(session)
    expect(patient.reload.sent_consent_at).to be_today
  end
end
