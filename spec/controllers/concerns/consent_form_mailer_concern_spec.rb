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
      let(:menacwy_programme) { CachedProgramme.menacwy }
      let(:td_ipv_programme) { CachedProgramme.td_ipv }
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
      let(:programmes) { [CachedProgramme.sample] }
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

  describe "#send_parental_contact_warning_if_needed" do
    subject(:send_warning) do
      sample.send_parental_contact_warning_if_needed(patient, consent_form)
    end

    let(:parent) do
      create(
        :parent,
        email: "existing@example.com",
        phone: "07987654321",
        phone_receive_updates: true
      )
    end
    let(:patient) { create(:patient, parents: [parent]) }
    let(:consent_form) do
      create(
        :consent_form,
        parent_email: "submitted@example.com",
        parent_phone: "07123456789"
      )
    end

    it "can be called directly" do
      expect { send_warning }.not_to raise_error
    end

    context "when patient has no parents" do
      let(:patient) { create(:patient, parents: []) }

      it "does not send any warning email" do
        expect { send_warning }.not_to have_delivered_email
      end

      it "does not send any warning SMS" do
        expect { send_warning }.not_to have_delivered_sms
      end
    end

    context "when submitted email and phone both match existing parent" do
      let(:consent_form) do
        create(
          :consent_form,
          parent_email: "existing@example.com",
          parent_phone: "07987654321"
        )
      end

      it "does not send any warning email" do
        expect { send_warning }.not_to have_delivered_email
      end

      it "does not send any warning SMS" do
        expect { send_warning }.not_to have_delivered_sms
      end
    end

    context "when only submitted email matches existing parent" do
      let(:consent_form) do
        create(
          :consent_form,
          parent_email: "existing@example.com",
          parent_phone: "07111111111"
        )
      end

      it "does not send any warning email" do
        expect { send_warning }.not_to have_delivered_email
      end

      it "does not send any warning SMS" do
        expect { send_warning }.not_to have_delivered_sms
      end
    end

    context "when only submitted phone matches existing parent" do
      let(:consent_form) do
        create(
          :consent_form,
          parent_email: "different@example.com",
          parent_phone: "07987654321"
        )
      end

      it "does not send any warning email" do
        expect { send_warning }.not_to have_delivered_email
      end

      it "does not send any warning SMS" do
        expect { send_warning }.not_to have_delivered_sms
      end
    end

    context "when neither email nor phone match existing parent" do
      it "sends warning email and SMS to existing parent" do
        expect { send_warning }.to have_delivered_email(
          :consent_unknown_contact_details_warning
        ).with(parent:, patient:, consent_form:).and have_delivered_sms(
                :consent_unknown_contact_details_warning
              ).with(parent:, patient:, consent_form:)
      end

      context "when parent has phone_receive_updates disabled" do
        let(:parent) do
          create(
            :parent,
            email: "existing@example.com",
            phone: "07987654321",
            phone_receive_updates: false
          )
        end

        it "sends warning email" do
          expect { send_warning }.to have_delivered_email(
            :consent_unknown_contact_details_warning
          ).with(parent:, patient:, consent_form:)
        end

        it "does not send warning SMS" do
          expect { send_warning }.not_to have_delivered_sms
        end
      end

      context "when multiple parents exist" do
        let(:parent2) do
          create(
            :parent,
            email: "parent2@example.com",
            phone: "07111111111",
            phone_receive_updates: true
          )
        end
        let(:patient) { create(:patient, parents: [parent, parent2]) }

        it "sends warnings to all existing parents" do
          expect { send_warning }.to have_delivered_email(
            :consent_unknown_contact_details_warning
          ).with(parent:, patient:, consent_form:).and have_delivered_email(
                  :consent_unknown_contact_details_warning
                ).with(
                  parent: parent2,
                  patient:,
                  consent_form:
                ).and have_delivered_sms(
                        :consent_unknown_contact_details_warning
                      ).with(
                        parent:,
                        patient:,
                        consent_form:
                      ).and have_delivered_sms(
                              :consent_unknown_contact_details_warning
                            ).with(parent: parent2, patient:, consent_form:)
        end
      end
    end
  end
end
