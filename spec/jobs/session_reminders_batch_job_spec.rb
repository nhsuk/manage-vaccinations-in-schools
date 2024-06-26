# frozen_string_literal: true

require "rails_helper"

describe SessionRemindersBatchJob, type: :job do
  before { ActionMailer::Base.deliveries.clear }

  it "sends emails to all patients' parents" do
    patient = create(:patient)
    session = create(:session, patients: [patient], date: 1.day.from_now)

    expect { described_class.perform_now(session) }.to send_email(
      to: patient.parent.email
    )

    expect(ActionMailer::Base.deliveries.count).to eq(1)
  end

  it "does not send a reminder if one has already been sent" do
    patient = create(:patient, session_reminder_sent_at: Time.zone.now)
    session = create(:session, patients: [patient], date: 1.day.from_now)

    expect { described_class.perform_now(session) }.not_to send_email(
      to: patient.parent.email
    )
  end

  it "updates the session_reminder_sent_at attribute for patients" do
    patient = create(:patient)
    session = create(:session, patients: [patient], date: 1.day.from_now)

    expect { described_class.perform_now(session) }.to(
      change { patient.reload.session_reminder_sent_at }
    )
  end
end
