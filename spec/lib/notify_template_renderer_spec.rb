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
        "You’ve agreed for Alex to have the nasal spray.",
      subteam_name: "School Nursing Team",
      subteam_email: "school@example.com",
      subteam_phone: "01234 567890"
    )
  end

  describe "email channel" do
    let(:renderer) { described_class.for(:email) }

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
  end

  describe "SMS channel" do
    let(:renderer) { described_class.for(:sms) }

    describe "#render" do
      subject(:rendered) do
        renderer.render(:consent_confirmation_given, personalisation)
      end

      it "renders the body with personalisation and sanitises smart quotes" do
        expect(rendered).not_to have_key(:subject)
        expect(rendered[:body]).to include("You've given consent for Alex")
        expect(rendered[:body]).to include("01234 567890")
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
            /in sms template 'consent_confirmation_given'/
          )
        end
      end
    end
  end
end
