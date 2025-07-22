# frozen_string_literal: true

describe ConsentFormMailerConcern do
  subject(:sample) { Class.new { include ConsentFormMailerConcern }.new }

  let(:consent_form) { create(:consent_form) }

  describe "#send_consent_form_confirmation" do
    subject(:send_consent_form_confirmation) do
      sample.send_consent_form_confirmation(consent_form)
    end

    it "sends a confirmation email" do
      expect { send_consent_form_confirmation }.to have_delivered_email(
        :consent_confirmation_given
      ).with(consent_form:, programmes: consent_form.programmes)
    end

    it "sends a consent given text" do
      expect { send_consent_form_confirmation }.to have_delivered_sms(
        :consent_confirmation_given
      ).with(consent_form:, programmes: consent_form.programmes)
    end

    context "when user refuses consent" do
      before { consent_form.update!(response: "refused") }

      it "sends an confirmation refused email" do
        expect { send_consent_form_confirmation }.to have_delivered_email(
          :consent_confirmation_refused
        ).with(consent_form:)
      end

      it "sends a consent refused text" do
        expect { send_consent_form_confirmation }.to have_delivered_sms(
          :consent_confirmation_refused
        ).with(consent_form:)
      end
    end

    context "when user only consents to one programme" do
      let(:menacwy_programme) { create(:programme, :menacwy) }
      let(:td_ipv_programme) { create(:programme, :td_ipv) }
      let(:programmes) { [menacwy_programme, td_ipv_programme] }
      let(:session) { create(:session, programmes:) }

      let(:consent_form) { create(:consent_form, session:) }

      before do
        consent_form.consent_form_programmes.first.update!(response: "given")
        consent_form.consent_form_programmes.second.update!(response: "refused")
      end

      it "sends a confirmation given and a confirmation refused email" do
        expect { send_consent_form_confirmation }.to have_delivered_email(
          :consent_confirmation_given
        ).with(
          consent_form:,
          programmes: [menacwy_programme]
        ).and have_delivered_email(:consent_confirmation_refused).with(
                consent_form:,
                programmes: [td_ipv_programme]
              )
      end

      it "sends a confirmation given and a confirmation refused text" do
        expect { send_consent_form_confirmation }.to have_delivered_sms(
          :consent_confirmation_given
        ).with(
          consent_form:,
          programmes: [menacwy_programme]
        ).and have_delivered_sms(:consent_confirmation_refused).with(
                consent_form:,
                programmes: [td_ipv_programme]
              )
      end
    end

    context "when a health question is yes" do
      before { consent_form.health_answers.last.response = "yes" }

      it "sends an confirmation needs triage email" do
        expect { send_consent_form_confirmation }.to have_delivered_email(
          :consent_confirmation_triage
        ).with(consent_form:, programmes: consent_form.programmes)
      end

      it "doesn't send a text" do
        expect { send_consent_form_confirmation }.not_to have_delivered_sms
      end
    end

    context "when there are no upcoming sessions" do
      let(:programmes) { [create(:programme)] }
      let(:team) { create(:team, :with_generic_clinic, programmes:) }
      let(:consent_form) do
        create(
          :consent_form,
          team:,
          school_confirmed: false,
          school: create(:school, team:),
          session: create(:session, team:, programmes:)
        )
      end

      it "sends an confirmation needs triage email" do
        expect { send_consent_form_confirmation }.to have_delivered_email(
          :consent_confirmation_clinic
        ).with(consent_form:, programmes: consent_form.programmes)
      end

      it "doesn't send a text" do
        expect { send_consent_form_confirmation }.not_to have_delivered_sms
      end
    end
  end
end
