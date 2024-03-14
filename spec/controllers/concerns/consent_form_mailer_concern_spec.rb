require "rails_helper"

describe ConsentFormMailerConcern do
  subject { Class.new { include ConsentFormMailerConcern }.new }

  let(:consent_form) { build(:consent_form) }
  let(:mail) { double(deliver_later: true) }

  before do
    allow(ConsentFormMailer).to receive_messages(
      confirmation: mail,
      confirmation_needs_triage: mail,
      confirmation_injection: mail,
      confirmation_refused: mail,
      give_feedback: mail
    )
  end

  describe "#send_record_mail" do
    it "sends confirmation_injection mail when user agrees to be contacted" do
      consent_form.contact_injection = true
      subject.send_record_mail(consent_form)

      expect(ConsentFormMailer).to have_received(:confirmation_injection).with(
        consent_form:
      )
      expect(mail).to have_received(:deliver_later).with(no_args).once
    end

    it "sends confirmation_refused mail when user refuses consent" do
      consent_form.response = :refused
      subject.send_record_mail(consent_form)

      expect(ConsentFormMailer).to have_received(:confirmation_refused).with(
        consent_form:
      )
      expect(mail).to have_received(:deliver_later).with(no_args).once
    end

    it "sends confirmation_needs_triage mail when a health question is yes" do
      consent_form.health_answers.last.response = "yes"
      subject.send_record_mail(consent_form)

      expect(ConsentFormMailer).to have_received(
        :confirmation_needs_triage
      ).with(consent_form:)
      expect(mail).to have_received(:deliver_later).with(no_args).once
    end

    it "sends confirmation mail when user agrees to consent" do
      subject.send_record_mail(consent_form)

      expect(ConsentFormMailer).to have_received(:confirmation).with(
        consent_form:
      )
      expect(mail).to have_received(:deliver_later).with(no_args).once
    end
  end

  describe "#send_feedback_request_mail" do
    it "sends an email" do
      subject.send_feedback_request_mail(consent_form:)

      expect(ConsentFormMailer).to have_received(:give_feedback).with(
        consent_form:
      )
      expect(mail).to have_received(:deliver_later).with(wait: 1.hour).once
    end
  end
end
