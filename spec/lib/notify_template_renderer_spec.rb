# frozen_string_literal: true

describe NotifyTemplateRenderer do
  let(:personalisation) do
    instance_double(
      GovukNotifyPersonalisation,
      short_patient_name: "Alex",
      full_and_preferred_patient_name: "Alex Smith",
      short_patient_name_apos: "Alex's",
      vaccination: "HPV vaccination",
      vaccination_and_dates: "HPV vaccination on Monday 10 March",
      location_name: "Springfield Primary",
      consented_vaccine_methods_message:
        "You've agreed for Alex to have the nasal spray.",
      subteam_name: "School Nursing Team",
      subteam_email: "school@example.com",
      subteam_phone: "01234 567890"
    )
  end

  describe "email channel" do
    let(:renderer) { described_class.for(:email) }

    describe "#template_exists?" do
      subject(:template_exists?) { renderer.template_exists?(template) }

      context "when the template file exists" do
        let(:template) { :consent_confirmation_given }

        it { should be true }
      end

      context "when the template file does not exist" do
        let(:template) { :non_existent_template }

        it { should be false }
      end
    end

    describe "#template_id_for" do
      subject(:template_id_for) { renderer.template_id_for(template) }

      context "when the local template file exists" do
        let(:template) { :consent_confirmation_given }

        it { should eq("c6c8dbfc-b429-4468-bd0b-176e771b5a8e") }
      end

      context "when the Notify template is configured" do
        let(:template) { :clinic_initial_invitation }

        it do
          expect(template_id_for).to eq(
            GOVUK_NOTIFY_EMAIL_TEMPLATES[:clinic_initial_invitation]
          )
        end
      end

      context "when the template name is unknown" do
        let(:template) { :nonexistent }

        it { should be_nil }
      end
    end

    describe "#template_name_for" do
      subject(:template_name_for) { renderer.template_name_for(template_id) }

      context "when the template_id matches a local template" do
        let(:template_id) { "c6c8dbfc-b429-4468-bd0b-176e771b5a8e" }

        it { should eq(:consent_confirmation_given) }
      end

      context "when the template_id matches a Notify template" do
        let(:template_id) do
          GOVUK_NOTIFY_EMAIL_TEMPLATES[:clinic_initial_invitation]
        end

        it { should eq(:clinic_initial_invitation) }
      end

      context "when the template_id is unknown" do
        let(:template_id) { "00000000-0000-0000-0000-000000000000" }

        it { should be_nil }
      end
    end

    describe "#render" do
      subject(:rendered) do
        renderer.render(:consent_confirmation_given, personalisation)
      end

      it "renders the subject from frontmatter" do
        expect(rendered).to include(:subject)
        expect(rendered[:subject]).to include("HPV vaccination")
        expect(rendered[:subject]).to include("Alex")
      end

      it "renders the body with personalisation" do
        expect(rendered).to include(:body)
        expect(rendered[:body]).to include("You’ve given consent")
        expect(rendered[:body]).to include("Alex")
        expect(rendered[:body]).to include("HPV vaccination")
        expect(rendered[:body]).to include("Springfield Primary")
        expect(rendered[:body]).to include("School Nursing Team")
      end

      context "when template is not found" do
        it "raises TemplateNotFound" do
          expect {
            renderer.render(:nonexistent_template, personalisation)
          }.to raise_error(
            NotifyTemplateRenderer::TemplateNotFound,
            /No template at/
          )
        end
      end

      context "when template references an undefined variable" do
        let(:incomplete_personalisation) { Object.new }

        it "raises NameError mentioning the template name and path" do
          expect {
            renderer.render(
              :consent_confirmation_given,
              incomplete_personalisation
            )
          }.to raise_error(
            NameError,
            /in email template 'consent_confirmation_given'/
          )
        end
      end
    end

    describe "#passthrough_configured?" do
      it { expect(renderer.passthrough_configured?).to be true }
    end
  end

  describe "SMS channel" do
    let(:renderer) { described_class.for(:sms) }

    describe "#template_exists?" do
      subject(:template_exists?) { renderer.template_exists?(template) }

      context "when the template file does not exist" do
        let(:template) { :non_existent_template }

        it { should be false }
      end
    end

    describe "#template_id_for" do
      subject(:template_id_for) { renderer.template_id_for(template) }

      context "when the Notify template is configured" do
        let(:template) { :clinic_initial_invitation }

        it { should eq(GOVUK_NOTIFY_SMS_TEMPLATES[:clinic_initial_invitation]) }
      end

      context "when the template name is unknown" do
        let(:template) { :nonexistent }

        it { should be_nil }
      end
    end

    describe "#template_name_for" do
      subject(:template_name_for) { renderer.template_name_for(template_id) }

      context "when the template_id matches a Notify template" do
        let(:template_id) do
          GOVUK_NOTIFY_SMS_TEMPLATES[:clinic_initial_invitation]
        end

        it { should eq(:clinic_initial_invitation) }
      end

      context "when the template_id is unknown" do
        let(:template_id) { "00000000-0000-0000-0000-000000000000" }

        it { should be_nil }
      end
    end

    describe "#render" do
      context "when template is not found" do
        it "raises TemplateNotFound" do
          expect {
            renderer.render(:nonexistent_template, personalisation)
          }.to raise_error(
            NotifyTemplateRenderer::TemplateNotFound,
            /No template at/
          )
        end
      end
    end

    describe "#passthrough_configured?" do
      it { expect(renderer.passthrough_configured?).to be true }
    end
  end
end
