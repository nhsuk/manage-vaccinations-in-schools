# frozen_string_literal: true

shared_examples_for "a Confirmable model" do
  describe "#confirmation_sent!" do
    it "sends confirmation_sent_at" do
      freeze_time do
        expect { subject.confirmation_sent! }.to change(
          subject,
          :confirmation_sent_at
        ).from(nil).to(Time.current)
      end
    end

    context "when already confirmed" do
      before { subject.confirmation_sent_at = 1.day.ago }

      it "doesn't change confirmation_sent_at" do
        expect { subject.confirmation_sent! }.not_to change(
          subject,
          :confirmation_sent_at
        )
      end
    end
  end
end
