# frozen_string_literal: true

describe ConsentRemindersSessionBatchJob do
  subject(:perform_now) do
    travel_to(today) { described_class.perform_now(session) }
  end

  let(:today) { Date.new(2024, 1, 1) }

  let(:programme) { create(:programme) }
  let(:parents) { create_list(:parent, 2) }

  let!(:patient_with_reminder_sent) do
    create(:patient, :consent_request_sent, :consent_reminder_sent, programme:)
  end
  let!(:patient_not_sent_reminder) do
    create(:patient, :consent_request_sent, parents:, programme:)
  end
  let!(:patient_with_consent) do
    create(:patient, :consent_given_triage_not_needed, programme:)
  end

  let(:session) do
    create(
      :session,
      programme:,
      patients: [
        patient_with_reminder_sent,
        patient_not_sent_reminder,
        patient_with_consent
      ]
    )
  end

  it "only sends emails to patients parents to whom they have not been sent yet" do
    expect { perform_now }.to have_enqueued_mail(
      ConsentMailer,
      :reminder
    ).twice.and have_enqueued_mail(ConsentMailer, :reminder).with(
                  params: {
                    parent: parents.first,
                    patient: patient_not_sent_reminder,
                    programme:,
                    session:
                  },
                  args: []
                ).and have_enqueued_mail(ConsentMailer, :reminder).with(
                        params: {
                          parent: parents.second,
                          patient: patient_not_sent_reminder,
                          programme:,
                          session:
                        },
                        args: []
                      )
  end

  it "only sends texts to patients parents to whom they have not been sent yet" do
    expect { perform_now }.to have_enqueued_text(:consent_reminder).with(
      parent: parents.first,
      patient: patient_not_sent_reminder,
      programme:,
      session:
    ).and have_enqueued_text(:consent_reminder).with(
            parent: parents.second,
            patient: patient_not_sent_reminder,
            programme:,
            session:
          )
  end

  it "updates the consent_reminder_sent_at attribute for patients" do
    expect { perform_now }.to change {
      patient_not_sent_reminder.reload.consent_reminder_sent_at
    }.to(today)
  end

  it "creates a consent notification record" do
    expect { perform_now }.to change(ConsentNotification, :count).by(1)

    consent_notification =
      ConsentNotification.find_by(
        programme:,
        patient: patient_not_sent_reminder,
        reminder: true
      )
    expect(consent_notification).not_to be_nil
    expect(consent_notification.sent_at).to be_today
  end
end
