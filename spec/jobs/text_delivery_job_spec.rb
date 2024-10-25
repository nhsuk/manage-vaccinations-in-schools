# frozen_string_literal: true

describe TextDeliveryJob do
  before(:all) do
    Rails.configuration.action_mailer.delivery_method = :notify
    Rails.configuration.action_mailer.notify_settings = { api_key: "abc" }
  end

  after(:all) { Rails.configuration.action_mailer.delivery_method = :test }

  before do
    allow(Notifications::Client).to receive(:new).with("abc").and_return(
      notifications_client
    )
    allow(notifications_client).to receive(:send_sms)
  end

  after { described_class.instance_variable_set("@client", nil) }

  let(:notifications_client) { instance_double(Notifications::Client) }

  describe "#perform_now" do
    subject(:perform_now) do
      described_class.perform_now(
        template_name,
        session:,
        consent:,
        consent_form:,
        parent:,
        patient:,
        patient_session:,
        programme:,
        vaccination_record:
      )
    end

    let(:template_name) { GOVUK_NOTIFY_TEXT_TEMPLATES.keys.first }
    let(:programme) { create(:programme) }
    let(:session) { create(:session, programme:) }
    let(:parent) { create(:parent, phone: "01234567890") }
    let(:consent) { nil }
    let(:consent_form) { nil }
    let(:patient) { create(:patient) }
    let(:patient_session) { nil }
    let(:vaccination_record) { nil }

    it "generates personalisation" do
      expect(GovukNotifyPersonalisation).to receive(:call).with(
        session:,
        consent:,
        consent_form:,
        parent:,
        patient:,
        patient_session:,
        programme:,
        vaccination_record:
      )
      perform_now
    end

    it "sends a text using GOV.UK Notify" do
      expect(notifications_client).to receive(:send_sms).with(
        phone_number: "01234567890",
        template_id: GOVUK_NOTIFY_TEXT_TEMPLATES[template_name],
        personalisation: an_instance_of(Hash)
      )
      perform_now
    end

    it "creates a log entry" do
      expect { perform_now }.to change(NotifyLogEntry, :count).by(1)

      notify_log_entry = NotifyLogEntry.last
      expect(notify_log_entry).to be_sms
      expect(notify_log_entry.recipient).to eq("01234567890")
      expect(notify_log_entry.template_id).to eq(
        GOVUK_NOTIFY_TEXT_TEMPLATES[template_name]
      )
      expect(notify_log_entry.patient).to eq(patient)
    end

    context "when the parent doesn't want to receive updates" do
      let(:parent) { create(:parent, phone_receive_updates: false) }

      it "doesn't send a text" do
        expect(notifications_client).not_to receive(:send_sms)
        perform_now
      end
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
        create(:consent_form, programme:, session:, parent_phone: "01234567890")
      end
      let(:parent) { nil }
      let(:patient) { nil }

      it "sends a text using GOV.UK Notify" do
        expect(notifications_client).to receive(:send_sms).with(
          phone_number: "01234567890",
          template_id: GOVUK_NOTIFY_TEXT_TEMPLATES[template_name],
          personalisation: an_instance_of(Hash)
        )
        perform_now
      end

      it "creates a log entry" do
        expect { perform_now }.to change(NotifyLogEntry, :count).by(1)

        notify_log_entry = NotifyLogEntry.last
        expect(notify_log_entry).to be_sms
        expect(notify_log_entry.recipient).to eq("01234567890")
        expect(notify_log_entry.template_id).to eq(
          GOVUK_NOTIFY_TEXT_TEMPLATES[template_name]
        )
        expect(notify_log_entry.consent_form).to eq(consent_form)
      end

      context "when the parent doesn't want to receive updates" do
        let(:consent_form) do
          create(
            :consent_form,
            programme:,
            session:,
            parent_phone_receive_updates: false
          )
        end

        it "doesn't send a text" do
          expect(notifications_client).not_to receive(:send_sms)
          perform_now
        end
      end

      context "when the parent doesn't have a phone number" do
        let(:consent_form) do
          create(:consent_form, programme:, session:, parent_phone: nil)
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
      described_class.perform_later(GOVUK_NOTIFY_TEXT_TEMPLATES.keys.first)
    end

    it "uses the mailer queue" do
      expect { perform_later }.to have_enqueued_job(described_class).on_queue(
        :mailer
      )
    end
  end
end
