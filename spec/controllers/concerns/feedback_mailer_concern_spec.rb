require "rails_helper"

describe FeedbackMailerConcern do
  subject { Class.new { include FeedbackMailerConcern }.new }

  let(:consent_form) { build(:consent_form) }
  let(:mail) { double(deliver_later: true) }

  before { allow(FeedbackMailer).to receive_messages(give_feedback: mail) }

  describe "#send_feedback_request_mail" do
    context "when a feedback request has not been sent" do
      let(:consent_form) { build(:consent_form, feedback_request_sent_at: nil) }

      it "sends an email" do
        subject.send_feedback_request_mail(consent_form:)

        expect(FeedbackMailer).to have_received(:give_feedback).with(
          consent_form:
        )
        expect(mail).to have_received(:deliver_later).with(wait: 1.hour).once
      end

      it "updates the feedback_request_sent_at" do
        subject.send_feedback_request_mail(consent_form:)
        expect(consent_form.feedback_request_sent_at).to be_within(1.second).of(
          Time.zone.now
        )
      end
    end

    context "when a feedback request has been sent" do
      let(:consent_form) do
        build(:consent_form, feedback_request_sent_at: Time.zone.now)
      end

      it "does not send an email" do
        subject.send_feedback_request_mail(consent_form:)

        expect(FeedbackMailer).not_to have_received(:give_feedback)
      end
    end
  end
end
