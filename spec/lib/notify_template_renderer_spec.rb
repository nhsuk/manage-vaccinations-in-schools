# frozen_string_literal: true

describe NotifyTemplateRenderer do
  describe "#template_exists?" do
    it "returns true when the template file exists" do
      renderer = described_class.for(:email)
      expect(renderer.template_exists?(:consent_confirmation_given)).to be true
    end

    it "returns false when the template file does not exist" do
      renderer = described_class.for(:email)
      expect(renderer.template_exists?(:nonexistent_template)).to be false
    end
  end

  describe "#render" do
    let(:personalisation) do
      instance_double(
        GovukNotifyPersonalisation,
        short_patient_name: "Alex",
        vaccination: "HPV vaccination",
        location_name: "Springfield Primary",
        consented_vaccine_methods_message: "You've agreed for Alex to have the nasal spray.",
        next_or_today_session_dates: "Monday 10 March",
        subteam_name: "School Nursing Team",
        subteam_email: "school@example.com",
        subteam_phone: "01234 567890"
      )
    end

    context "for email" do
      subject(:rendered) do
        described_class.for(:email).render(:consent_confirmation_given, personalisation)
      end

      it "returns subject and body" do
        expect(rendered).to include(:subject, :body)
      end

      it "renders the subject from frontmatter" do
        expect(rendered[:subject]).to include("HPV vaccination")
        expect(rendered[:subject]).to include("Alex")
      end

      it "renders the body with personalisation" do
        expect(rendered[:body]).to include("Dear parent or guardian")
        expect(rendered[:body]).to include("Alex")
        expect(rendered[:body]).to include("HPV vaccination")
        expect(rendered[:body]).to include("Springfield Primary")
        expect(rendered[:body]).to include("Monday 10 March")
        expect(rendered[:body]).to include("School Nursing Team")
      end
    end

    context "when template is not found" do
      it "raises TemplateNotFound" do
        expect {
          described_class.for(:email).render(:nonexistent_template, personalisation)
        }.to raise_error(NotifyTemplateRenderer::TemplateNotFound, /No template at/)
      end
    end
  end

  describe "#passthrough_template_id" do
    it "returns the email passthrough placeholder for :email" do
      renderer = described_class.for(:email)
      expect(renderer.passthrough_template_id).to eq(
        described_class::PASSTHROUGH_EMAIL_TEMPLATE_ID
      )
    end

    it "returns nil for :sms until we add an SMS passthrough constant" do
      renderer = described_class.for(:sms)
      expect(renderer.passthrough_template_id).to be_nil
    end
  end

  describe "#passthrough_configured?" do
    it "returns false for email when placeholder is unchanged" do
      renderer = described_class.for(:email)
      expect(renderer.passthrough_configured?).to be false
    end

    it "returns false for :sms when no constant is set" do
      renderer = described_class.for(:sms)
      expect(renderer.passthrough_configured?).to be false
    end
  end

  describe "#template_id_for" do
    it "returns template_id from frontmatter when local file exists" do
      renderer = described_class.for(:email)
      expect(renderer.template_id_for(:consent_confirmation_given)).to eq(
        "c6c8dbfc-b429-4468-bd0b-176e771b5a8e"
      )
    end

    it "returns UUID from config hash when no local file" do
      renderer = described_class.for(:email)
      expect(renderer.template_id_for(:clinic_initial_invitation)).to eq(
        GOVUK_NOTIFY_EMAIL_TEMPLATES[:clinic_initial_invitation]
      )
    end

    it "returns nil for unknown template name" do
      renderer = described_class.for(:email)
      expect(renderer.template_id_for(:nonexistent)).to be_nil
    end
  end

  describe "#template_name_for" do
    it "returns template name from local frontmatter when template_id matches" do
      renderer = described_class.for(:email)
      uuid = "c6c8dbfc-b429-4468-bd0b-176e771b5a8e"
      expect(renderer.template_name_for(uuid)).to eq(:consent_confirmation_given)
    end

    it "returns template name from config hash when no local file has that template_id" do
      renderer = described_class.for(:email)
      uuid = GOVUK_NOTIFY_EMAIL_TEMPLATES[:clinic_initial_invitation]
      expect(renderer.template_name_for(uuid)).to eq(:clinic_initial_invitation)
    end

    it "returns nil for unknown template_id" do
      renderer = described_class.for(:email)
      expect(renderer.template_name_for("00000000-0000-0000-0000-000000000000")).to be_nil
    end
  end

  describe "#parse_frontmatter (private, tested via render)" do
    it "parses YAML frontmatter and body" do
      content = <<~TEXT
        ---
        subject: "Hello ((name))"
        ---
        Body here
      TEXT
      renderer = described_class.for(:email)
      frontmatter, body = renderer.send(:parse_frontmatter, content)
      expect(frontmatter).to eq("subject" => "Hello ((name))")
      expect(body).to eq("Body here\n")
    end

    it "returns empty frontmatter when no frontmatter" do
      content = "Just body"
      renderer = described_class.for(:email)
      frontmatter, body = renderer.send(:parse_frontmatter, content)
      expect(frontmatter).to eq({})
      expect(body).to eq("Just body")
    end
  end
end
