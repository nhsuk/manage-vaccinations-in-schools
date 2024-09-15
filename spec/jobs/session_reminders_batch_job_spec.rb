# frozen_string_literal: true

describe SessionRemindersBatchJob do
  subject(:perform_now) { described_class.perform_now(session) }

  let(:parents) { create_list(:parent, 2, :recorded) }
  let(:patient) { create(:patient, parents:) }
  let(:session) { create(:session, patients: [patient], date: 1.day.from_now) }

  context "when consent has been given" do
    before do
      create(
        :consent,
        :given,
        :recorded,
        patient:,
        parent: parents.first,
        programme: session.programme
      )
      create(
        :consent,
        :refused,
        :recorded,
        patient:,
        parent: parents.second,
        programme: session.programme
      )
    end

    it "sends an email to the parent who consented" do
      expect { perform_now }.to send_email(to: parents.first.email)
    end

    it "does not send a reminder if one has already been sent" do
      patient.update!(session_reminder_sent_at: Time.zone.now)
      expect { perform_now }.not_to send_email(to: parents.first.email)
    end
  end

  it "updates the session_reminder_sent_at attribute for patients" do
    expect { perform_now }.to(
      change { patient.reload.session_reminder_sent_at }
    )
  end
end
