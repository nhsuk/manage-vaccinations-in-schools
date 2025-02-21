# frozen_string_literal: true

describe EmailDeliveryJob do
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
    allow(notifications_client).to receive(:send_email).and_return(response)
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
        programme:,
        sent_by:,
        vaccination_record:
      )
    end

    let(:template_name) { GOVUK_NOTIFY_EMAIL_TEMPLATES.keys.first }
    let(:programme) { create(:programme) }
    let(:organisation) do
      create(
        :organisation,
        reply_to_id: "54bf1d28-8851-43f2-893d-1853f43a50cd",
        programmes: [programme]
      )
    end
    let(:session) { create(:session, programme:, organisation:) }
    let(:parent) { create(:parent, email: "test@example.com") }
    let(:consent) { nil }
    let(:consent_form) { nil }
    let(:patient) { create(:patient) }
    let(:sent_by) { create(:user) }
    let(:vaccination_record) { nil }

    it "generates personalisation" do
      expect(GovukNotifyPersonalisation).to receive(:call).with(
        session:,
        consent:,
        consent_form:,
        patient:,
        programme:,
        vaccination_record:
      )
      perform_now
    end

    it "sends a text using GOV.UK Notify" do
      expect(notifications_client).to receive(:send_email).with(
        email_address: "test@example.com",
        email_reply_to_id: "54bf1d28-8851-43f2-893d-1853f43a50cd",
        personalisation: an_instance_of(Hash),
        template_id: GOVUK_NOTIFY_EMAIL_TEMPLATES[template_name]
      )
      perform_now
    end

    context "without a reply-to id" do
      let(:organisation) { create(:organisation, programmes: [programme]) }

      it "sends a text using GOV.UK Notify" do
        expect(notifications_client).to receive(:send_email).with(
          email_address: "test@example.com",
          personalisation: an_instance_of(Hash),
          template_id: GOVUK_NOTIFY_EMAIL_TEMPLATES[template_name]
        )
        perform_now
      end
    end

    it "creates a log entry" do
      expect { perform_now }.to change(NotifyLogEntry, :count).by(1)

      notify_log_entry = NotifyLogEntry.last
      expect(notify_log_entry).to be_email
      expect(notify_log_entry.delivery_id).to eq(response.id)
      expect(notify_log_entry.recipient).to eq("test@example.com")
      expect(notify_log_entry.template_id).to eq(
        GOVUK_NOTIFY_EMAIL_TEMPLATES[template_name]
      )
      expect(notify_log_entry.parent).to eq(parent)
      expect(notify_log_entry.patient).to eq(patient)
      expect(notify_log_entry.sent_by).to eq(sent_by)
    end

    context "when the parent doesn't have an email address" do
      let(:parent) { create(:parent, email: nil) }

      it "doesn't send a text" do
        expect(notifications_client).not_to receive(:send_email)
        perform_now
      end
    end

    context "with a consent form" do
      let(:consent_form) do
        create(
          :consent_form,
          programme:,
          session:,
          parent_email: "test@example.com"
        )
      end
      let(:parent) { nil }
      let(:patient) { nil }

      it "sends a text using GOV.UK Notify" do
        expect(notifications_client).to receive(:send_email).with(
          email_address: "test@example.com",
          email_reply_to_id: "54bf1d28-8851-43f2-893d-1853f43a50cd",
          personalisation: an_instance_of(Hash),
          template_id: GOVUK_NOTIFY_EMAIL_TEMPLATES[template_name]
        )
        perform_now
      end

      context "without a reply-to id" do
        let(:organisation) { create(:organisation, programmes: [programme]) }

        it "sends a text using GOV.UK Notify" do
          expect(notifications_client).to receive(:send_email).with(
            email_address: "test@example.com",
            personalisation: an_instance_of(Hash),
            template_id: GOVUK_NOTIFY_EMAIL_TEMPLATES[template_name]
          )
          perform_now
        end
      end

      it "creates a log entry" do
        expect { perform_now }.to change(NotifyLogEntry, :count).by(1)

        notify_log_entry = NotifyLogEntry.last
        expect(notify_log_entry).to be_email
        expect(notify_log_entry.delivery_id).to eq(response.id)
        expect(notify_log_entry.recipient).to eq("test@example.com")
        expect(notify_log_entry.template_id).to eq(
          GOVUK_NOTIFY_EMAIL_TEMPLATES[template_name]
        )
        expect(notify_log_entry.consent_form).to eq(consent_form)
      end

      context "when the parent doesn't have a phone number" do
        let(:consent_form) do
          create(:consent_form, programme:, session:, parent_email: nil)
        end

        it "doesn't send a text" do
          expect(notifications_client).not_to receive(:send_email)
          perform_now
        end
      end
    end
  end

  describe "#perform_later" do
    subject(:perform_later) do
      described_class.perform_later(GOVUK_NOTIFY_EMAIL_TEMPLATES.keys.first)
    end

    it "uses the mailer queue" do
      expect { perform_later }.to have_enqueued_job(described_class).on_queue(
        :mailer
      )
    end
  end
end
