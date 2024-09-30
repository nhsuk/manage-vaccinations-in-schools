# frozen_string_literal: true

describe ConsentRequestsSessionBatchJob do
  subject(:perform_now) do
    travel_to(today) { described_class.perform_now(session) }
  end

  let(:today) { Date.new(2024, 1, 1) }

  let(:programme) { create(:programme) }
  let(:parents) { create_list(:parent, 2) }

  let!(:patient_with_consent_sent) do
    create(:patient, :consent_request_sent, programme:)
  end
  let!(:patient_not_sent_consent) { create(:patient, parents:) }
  let!(:patient_with_consent) do
    create(:patient, :consent_given_triage_not_needed, programme:)
  end

  let(:session) do
    create(
      :session,
      patients: [
        patient_with_consent_sent,
        patient_not_sent_consent,
        patient_with_consent
      ],
      programmes: [programme]
    )
  end

  it "only sends emails to patient's parents to whom they have not been sent yet" do
    expect { perform_now }.to send_email(
      to: parents.first.email
    ).and send_email(to: parents.second.email)

    expect(ActionMailer::Base.deliveries.count).to eq(2)
  end

  it "updates the consent_request_sent_at attribute for patients" do
    expect { perform_now }.to change {
      patient_not_sent_consent.reload.consent_request_sent_at
    }.to(today)
  end

  it "creates a consent notification record" do
    expect { perform_now }.to change(ConsentNotification, :count).by(1)

    consent_notification =
      ConsentNotification.find_by(
        programme:,
        patient: patient_not_sent_consent,
        reminder: false
      )
    expect(consent_notification).not_to be_nil
    expect(consent_notification.sent_at).to be_today
  end
end
