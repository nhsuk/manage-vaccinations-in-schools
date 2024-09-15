# frozen_string_literal: true

describe ConsentFormMailerConcern do
  subject(:sample) { Class.new { include ConsentFormMailerConcern }.new }

  let(:consent_form) { create(:consent_form) }

  describe "#send_record_mail" do
    subject(:send_record_mail) { sample.send_record_mail(consent_form) }

    it "sends a confirmation email" do
      expect { send_record_mail }.to have_enqueued_mail(
        ConsentMailer,
        :confirmation
      ).with(params: { consent_form: }, args: [])
    end

    it "sends a feedback email" do
      today = Time.zone.local(2024, 1, 1)

      expect { travel_to(today) { send_record_mail } }.to have_enqueued_mail(
        ConsentMailer,
        :give_feedback
      ).with(params: { consent_form: }, args: []).at(today + 1.hour)
    end

    context "when user agrees to be contacted about injections" do
      before { consent_form.contact_injection = true }

      it "sends an injection confirmation email" do
        expect { send_record_mail }.to have_enqueued_mail(
          ConsentMailer,
          :confirmation_injection
        ).with(params: { consent_form: }, args: [])
      end
    end

    context "when user refuses consent" do
      before { consent_form.response = :refused }

      it "sends an confirmation refused email" do
        expect { send_record_mail }.to have_enqueued_mail(
          ConsentMailer,
          :confirmation_refused
        ).with(params: { consent_form: }, args: [])
      end
    end

    context "when a health question is yes" do
      before { consent_form.health_answers.last.response = "yes" }

      it "sends an confirmation needs triage email" do
        expect { send_record_mail }.to have_enqueued_mail(
          ConsentMailer,
          :confirmation_needs_triage
        ).with(params: { consent_form: }, args: [])
      end
    end
  end
end
