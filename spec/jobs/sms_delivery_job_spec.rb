# frozen_string_literal: true

describe SMSDeliveryJob do
  before(:all) do
    Settings.govuk_notify.enabled = true
    Settings.govuk_notify.test_key = "abc"
  end

  after(:all) { Settings.govuk_notify.enabled = false }

  let(:response) do
    instance_double(
      Notifications::Client::ResponseNotification,
      id: SecureRandom.uuid
    )
  end
  let(:notifications_client) { instance_double(Notifications::Client) }

  before do
    allow(Notifications::Client).to receive(:new).with("abc").and_return(
      notifications_client
    )
    allow(notifications_client).to receive(:send_sms).and_return(response)
  end

  after { described_class.instance_variable_set("@client", nil) }

  describe "#perform_now" do
    subject(:perform_now) do
      described_class.perform_now(
        template_name,
        session:,
        consent:,
        consent_form:,
        parent:,
        patient:,
        programmes:,
        sent_by:,
        triage:,
        vaccination_record:
      )
    end

    let(:template_name) { GOVUK_NOTIFY_SMS_TEMPLATES.keys.first }
    let(:programmes) { [create(:programme)] }
    let(:session) { create(:session, programmes:) }
    let(:parent) { create(:parent, phone: "01234 567890") }
    let(:consent) { nil }
    let(:consent_form) { nil }
    let(:patient) { create(:patient) }
    let(:sent_by) { create(:user) }
    let(:triage) { create(:triage, programme: programmes.first) }
    let(:vaccination_record) { nil }

    it "generates personalisation" do
      expect(GovukNotifyPersonalisation).to receive(:new).with(
        session:,
        consent:,
        consent_form:,
        parent:,
        patient:,
        programmes:,
        triage:,
        vaccination_record:
      ).and_call_original
      perform_now
    end

    it "sends a text using GOV.UK Notify" do
      expect(notifications_client).to receive(:send_sms).with(
        phone_number: "01234 567890",
        template_id: GOVUK_NOTIFY_SMS_TEMPLATES[template_name],
        personalisation: an_instance_of(Hash)
      )
      perform_now
    end

    it "creates a log entry" do
      expect { perform_now }.to change(NotifyLogEntry, :count).by(1)

      notify_log_entry = NotifyLogEntry.last
      expect(notify_log_entry).to be_sms
      expect(notify_log_entry.delivery_id).to eq(response.id)
      expect(notify_log_entry.recipient).to eq("01234 567890")
      expect(notify_log_entry.template_id).to eq(
        GOVUK_NOTIFY_SMS_TEMPLATES[template_name]
      )
      expect(notify_log_entry.parent).to eq(parent)
      expect(notify_log_entry.patient).to eq(patient)
      expect(notify_log_entry.programme_ids).to eq(programmes.map(&:id))
      expect(notify_log_entry.sent_by).to eq(sent_by)
    end

    context "when the parent doesn't have a phone number" do
      let(:parent) { create(:parent, phone: nil) }

      it "doesn't send a text" do
        expect(notifications_client).not_to receive(:send_sms)
        perform_now
      end
    end

    context "with a consent form" do
      let(:consent_form) do
        create(:consent_form, session:, parent_phone: "01234567890")
      end
      let(:parent) { nil }
      let(:patient) { nil }

      it "sends a text using GOV.UK Notify" do
        expect(notifications_client).to receive(:send_sms).with(
          phone_number: "01234 567890",
          template_id: GOVUK_NOTIFY_SMS_TEMPLATES[template_name],
          personalisation: an_instance_of(Hash)
        )
        perform_now
      end

      it "creates a log entry" do
        expect { perform_now }.to change(NotifyLogEntry, :count).by(1)

        notify_log_entry = NotifyLogEntry.last
        expect(notify_log_entry).to be_sms
        expect(notify_log_entry.delivery_id).to eq(response.id)
        expect(notify_log_entry.recipient).to eq("01234 567890")
        expect(notify_log_entry.template_id).to eq(
          GOVUK_NOTIFY_SMS_TEMPLATES[template_name]
        )
        expect(notify_log_entry.consent_form).to eq(consent_form)
        expect(notify_log_entry.programme_ids).to eq(programmes.map(&:id))
      end

      context "when the parent doesn't have a phone number" do
        let(:consent_form) do
          create(:consent_form, session:, parent_phone: nil)
        end

        it "doesn't send a text" do
          expect(notifications_client).not_to receive(:send_sms)
          perform_now
        end
      end
    end
  end

  describe "#perform_later" do
    subject(:perform_later) do
      described_class.perform_later(GOVUK_NOTIFY_SMS_TEMPLATES.keys.first)
    end

    it "uses the mailer queue" do
      expect { perform_later }.to have_enqueued_job(described_class).on_queue(
        :mailer
      )
    end
  end
end
