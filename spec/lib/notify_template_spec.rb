# frozen_string_literal: true

describe NotifyTemplate do
  describe ".find" do
    context "with a locally-migrated email template" do
      subject(:template) do
        described_class.find(:consent_confirmation_given, channel: :email)
      end

      it { should_not be_nil }
      it { should be_local }

      it "has a UUID as the template ID" do
        expect(template.id).to match(/\A[0-9a-f-]{36}\z/)
      end
    end

    context "with a locally-migrated SMS template" do
      subject(:template) do
        described_class.find(:consent_confirmation_given, channel: :sms)
      end

      it { should_not be_nil }
      it { should be_local }
    end

    context "with a Notify-hosted email template" do
      subject(:template) do
        described_class.find(:clinic_initial_invitation, channel: :email)
      end

      it { should_not be_nil }
      it { should_not be_local }
    end

    context "with a Notify-hosted SMS template" do
      subject(:template) do
        described_class.find(:clinic_initial_invitation, channel: :sms)
      end

      it { should_not be_nil }
      it { should_not be_local }
    end

    context "with an unknown template name" do
      subject(:template) do
        described_class.find(:nonexistent_template, channel: :email)
      end

      it { should be_nil }
    end
  end

  describe ".find_by_id" do
    context "with a locally-migrated template's ID" do
      subject(:template) do
        described_class.find_by_id(template_id, channel: :email)
      end

      let(:template_id) do
        described_class.find(:consent_confirmation_given, channel: :email).id
      end

      it { should_not be_nil }
      it { should be_local }

      it "resolves the template name" do
        expect(template.name).to eq(:consent_confirmation_given)
      end
    end

    context "with a Notify-hosted template's ID" do
      subject(:template) do
        described_class.find_by_id(template_id, channel: :email)
      end

      let(:template_id) do
        described_class.find(:clinic_initial_invitation, channel: :email).id
      end

      it { should_not be_nil }
      it { should_not be_local }
    end

    context "with a retired template's ID" do
      subject(:template) do
        described_class.find_by_id(template_id, channel: :email)
      end

      let(:template_id) { GOVUK_NOTIFY_UNUSED_TEMPLATES.keys.first }

      it { should_not be_nil }

      it "resolves the template name" do
        expect(template.name).to eq(GOVUK_NOTIFY_UNUSED_TEMPLATES[template_id])
      end
    end

    context "with an unknown ID" do
      subject(:template) do
        described_class.find_by_id(
          "00000000-0000-0000-0000-000000000000",
          channel: :email
        )
      end

      it { should be_nil }
    end

    context "with a blank ID" do
      subject(:template) { described_class.find_by_id(nil, channel: :email) }

      it { should be_nil }
    end
  end

  describe ".exists?" do
    context "with a locally-migrated template" do
      it "returns true for source: :local" do
        expect(
          described_class.exists?(
            :consent_confirmation_given,
            channel: :email,
            source: :local
          )
        ).to be true
      end

      it "returns false for source: :govuk_notify" do
        expect(
          described_class.exists?(
            :consent_confirmation_given,
            channel: :email,
            source: :govuk_notify
          )
        ).to be false
      end

      it "returns true for source: :any (default)" do
        expect(
          described_class.exists?(:consent_confirmation_given, channel: :email)
        ).to be true
      end
    end

    context "with a Notify-hosted template" do
      let(:template_name) { :clinic_initial_invitation }

      it "returns false for source: :local" do
        expect(
          described_class.exists?(
            template_name,
            channel: :email,
            source: :local
          )
        ).to be false
      end

      it "returns true for source: :govuk_notify" do
        expect(
          described_class.exists?(
            template_name,
            channel: :email,
            source: :govuk_notify
          )
        ).to be true
      end

      it "returns true for source: :any (default)" do
        expect(
          described_class.exists?(template_name, channel: :email)
        ).to be true
      end
    end

    context "with an unknown template" do
      it "returns false" do
        expect(
          described_class.exists?(:nonexistent, channel: :email)
        ).to be false
      end
    end

    context "with an unknown source" do
      it "raises ArgumentError" do
        expect {
          described_class.exists?(
            :consent_school_request_hpv,
            channel: :email,
            source: :unknown
          )
        }.to raise_error(ArgumentError, /Unknown source/)
      end
    end
  end

  context "local SMS templates" do
    # smart quotes should not be used in SMS template bodies and subject lines
    # to avoid Notify switching to UCS-2 encoding and
    # dropping the character limit per SMS to 70 characters
    # https://www.notifications.service.gov.uk/pricing/text-messages

    it "does not contain any smart quotes of any kind" do
      all_sms_template_files =
        Dir.glob(Rails.root.join("app/views/notify_templates/sms/*.text.erb"))
      all_sms_template_files.each do |file|
        content = File.read(file, encoding: "UTF-8")
        %w[“ ’ ’ ”].each { |quote| expect(content).not_to include(quote) }
      end
    end
  end
end
