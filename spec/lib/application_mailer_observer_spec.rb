# frozen_string_literal: true

describe ApplicationMailerObserver do
  subject(:delivered_email) { described_class.delivered_email(message) }

  let(:session) { patient_session.session }
  let(:patient_session) { create(:patient_session, :delay_vaccination) }
  let(:consent) { patient_session.patient.consents.first }

  let(:message) { TriageMailer.with(consent:, session:).vaccination_at_clinic }

  it "creates a timeline event" do
    expect { delivered_email }.to change(NotifyLogEntry, :count).by(1)
  end

  it "sets the attributes" do
    notify_log_entry = delivered_email.first

    expect(notify_log_entry).to be_email
    expect(notify_log_entry.patient).to eq(patient_session.patient)
    expect(notify_log_entry.recipient).to eq(consent.parent.email)
    expect(notify_log_entry.template_id).to eq(
      GOVUK_NOTIFY_EMAIL_TEMPLATES.fetch(:triage_vaccination_at_clinic)
    )
  end

  it "is called when an email is sent" do
    expect(described_class).to receive(:delivered_email).with(message)

    message.deliver_now
  end
end
