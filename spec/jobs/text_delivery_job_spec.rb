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

  describe "#perform" do
    subject(:perform) do
      described_class.new.perform(
        template_name,
        session:,
        consent:,
        consent_form:,
        parent:,
        patient:,
        patient_session:,
        vaccination_record:
      )
    end

    let(:template_name) { GOVUK_NOTIFY_TEXT_TEMPLATES.keys.first }
    let(:session) { create(:session) }
    let(:parent) { create(:parent, phone: "01234567890") }
    let(:consent) { nil }
    let(:consent_form) { nil }
    let(:patient) { create(:patient) }
    let(:patient_session) { nil }
    let(:vaccination_record) { nil }

    after { perform }

    it "generates personalisation" do
      expect(GovukNotifyPersonalisation).to receive(:call).with(
        session:,
        consent:,
        consent_form:,
        parent:,
        patient:,
        patient_session:,
        vaccination_record:
      )
    end

    it "sends a text using GOV.UK Notify" do
      expect(notifications_client).to receive(:send_sms).with(
        phone_number: "01234567890",
        template_id: GOVUK_NOTIFY_TEXT_TEMPLATES[template_name],
        personalisation: an_instance_of(Hash)
      )
    end

    context "when the parent doesn't want to receive updates" do
      let(:parent) { create(:parent, phone_receive_updates: false) }

      it "doesn't send a text" do
        expect(notifications_client).not_to receive(:send_sms)
      end
    end

    context "when the parent doesn't have a phone number" do
      let(:parent) { create(:parent, phone: nil) }

      it "doesn't send a text" do
        expect(notifications_client).not_to receive(:send_sms)
      end
    end

    context "with a consent form" do
      let(:consent_form) { create(:consent_form, parent_phone: "01234567890") }
      let(:parent) { nil }
      let(:patient) { nil }

      it "sends a text using GOV.UK Notify" do
        expect(notifications_client).to receive(:send_sms).with(
          phone_number: "01234567890",
          template_id: GOVUK_NOTIFY_TEXT_TEMPLATES[template_name],
          personalisation: an_instance_of(Hash)
        )
      end

      context "when the parent doesn't want to receive updates" do
        let(:consent_form) do
          create(:consent_form, parent_phone_receive_updates: false)
        end

        it "doesn't send a text" do
          expect(notifications_client).not_to receive(:send_sms)
        end
      end

      context "when the parent doesn't have a phone number" do
        let(:consent_form) { create(:consent_form, parent_phone: nil) }

        it "doesn't send a text" do
          expect(notifications_client).not_to receive(:send_sms)
        end
      end
    end
  end
end
