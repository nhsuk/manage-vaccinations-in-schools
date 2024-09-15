# frozen_string_literal: true

describe ConsentFormMailerConcern do
  subject(:sample) { Class.new { include ConsentFormMailerConcern }.new }

  let(:consent_form) { create(:consent_form) }

  describe "#send_consent_form_confirmation" do
    subject(:send_consent_form_confirmation) do
      sample.send_consent_form_confirmation(consent_form)
    end

    it "sends a confirmation email" do
      expect { send_consent_form_confirmation }.to have_enqueued_mail(
        ConsentMailer,
        :confirmation
      ).with(params: { consent_form: }, args: [])
    end

    it "sends a conset given text" do
      expect { send_consent_form_confirmation }.to have_enqueued_text(
        :consent_given
      ).with(consent_form:)
    end

    it "sends a feedback email" do
      today = Time.zone.local(2024, 1, 1)

      expect {
        travel_to(today) { send_consent_form_confirmation }
      }.to have_enqueued_mail(ConsentMailer, :give_feedback).with(
        params: {
          consent_form:
        },
        args: []
      ).at(today + 1.hour)
    end

    context "when user agrees to be contacted about injections" do
      before { consent_form.contact_injection = true }

      it "sends an injection confirmation email" do
        expect { send_consent_form_confirmation }.to have_enqueued_mail(
          ConsentMailer,
          :confirmation_injection
        ).with(params: { consent_form: }, args: [])
      end

      it "doesn't send a text" do
        expect { send_consent_form_confirmation }.not_to have_enqueued_text
      end
    end

    context "when user refuses consent" do
      before { consent_form.response = :refused }

      it "sends an confirmation refused email" do
        expect { send_consent_form_confirmation }.to have_enqueued_mail(
          ConsentMailer,
          :confirmation_refused
        ).with(params: { consent_form: }, args: [])
      end

      it "sends a consent refused text" do
        expect { send_consent_form_confirmation }.to have_enqueued_text(
          :consent_refused
        ).with(consent_form:)
      end
    end

    context "when a health question is yes" do
      before { consent_form.health_answers.last.response = "yes" }

      it "sends an confirmation needs triage email" do
        expect { send_consent_form_confirmation }.to have_enqueued_mail(
          ConsentMailer,
          :confirmation_needs_triage
        ).with(params: { consent_form: }, args: [])
      end

      it "doesn't send a text" do
        expect { send_consent_form_confirmation }.not_to have_enqueued_text
      end
    end
  end
end
