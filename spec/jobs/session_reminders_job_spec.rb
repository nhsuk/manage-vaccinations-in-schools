# frozen_string_literal: true

describe SessionRemindersJob do
  subject(:perform_now) { described_class.perform_now }

  before { Flipper.enable(:scheduled_emails) }

  let(:programme) { create(:programme, :active) }
  let(:parents) { create_list(:parent, 2, :recorded) }
  let(:patient) { create(:patient, parents:) }

  let!(:consent) do
    create(
      :consent,
      :given,
      :recorded,
      patient:,
      parent: parents.first,
      programme:
    )
  end

  context "for an active session tomorrow" do
    let!(:session) do
      create(:session, programme:, date: Date.tomorrow, patients: [patient])
    end
    let(:patient_session) { PatientSession.find_by!(patient:, session:) }

    it "sends an email to the parent who consented" do
      expect { perform_now }.to have_enqueued_mail(
        SessionMailer,
        :reminder
      ).with(params: { consent:, patient_session: }, args: [])
    end

    it "does not send a reminder if one has already been sent" do
      patient_session.update!(reminder_sent_at: Time.zone.now)
      expect { perform_now }.not_to have_enqueued_mail(SessionMailer, :reminder)
    end

    it "updates the reminder_sent_at attribute for patient sessions" do
      expect { perform_now }.to(
        change { patient_session.reload.reminder_sent_at }
      )
    end
  end

  context "for a session today" do
    before do
      create(:session, programme:, date: Time.zone.today, patients: [patient])
    end

    it "doesn't send an email" do
      expect { perform_now }.not_to have_enqueued_mail(SessionMailer, :reminder)
    end
  end

  context "for a session yesterday" do
    before do
      create(:session, programme:, date: Date.yesterday, patients: [patient])
    end

    it "doesn't send an email" do
      expect { perform_now }.not_to have_enqueued_mail(SessionMailer, :reminder)
    end
  end

  context "for a draft session tomorrow" do
    before do
      create(
        :session,
        :draft,
        programme:,
        date: Date.tomorrow,
        patients: [patient]
      )
    end

    it "doesn't send an email" do
      expect { perform_now }.not_to have_enqueued_mail(SessionMailer, :reminder)
    end
  end
end
