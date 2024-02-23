# == Schema Information
#
# Table name: consents
#
#  id                          :bigint           not null, primary key
#  health_answers              :jsonb
#  parent_contact_method       :integer
#  parent_contact_method_other :text
#  parent_email                :text
#  parent_name                 :text
#  parent_phone                :text
#  parent_relationship         :integer
#  parent_relationship_other   :text
#  reason_for_refusal          :integer
#  reason_for_refusal_other    :text
#  recorded_at                 :datetime
#  response                    :integer
#  route                       :integer          not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  campaign_id                 :bigint           not null
#  patient_id                  :bigint           not null
#
# Indexes
#
#  index_consents_on_campaign_id  (campaign_id)
#  index_consents_on_patient_id   (patient_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id)
#  fk_rails_...  (patient_id => patients.id)
#
require "rails_helper"

RSpec.describe Consent do
  describe "when consent given by parent or guardian, all health questions are no" do
    it "does not require triage" do
      response = build(:consent_given, parent_relationship: :mother)

      expect(response).not_to be_triage_needed
    end
  end

  describe "when consent given by someone who's not a parent or a guardian" do
    it "does require triage" do
      response = build(:consent_given, parent_relationship: :other)

      expect(response).to be_triage_needed
    end
  end

  describe "when consent given by parent or guardian, but some info for health questions" do
    it "does require triage" do
      health_answers = [
        HealthAnswer.new(
          question:
            "Does the child have a disease or treatment that severely affects their immune system?",
          response: "yes"
        )
      ]
      response =
        build(:consent_given, parent_relationship: :mother, health_answers:)

      expect(response).to be_triage_needed
    end
  end

  describe "#reasons_triage_needed" do
    context "parent relationship is other" do
      it "returns check parental responsibility" do
        response = build(:consent_given, :from_granddad)

        expect(response.reasons_triage_needed).to eq(
          ["Check parental responsibility"]
        )
      end
    end

    context "health questions indicate followup needed" do
      it "returns notes need triage" do
        response = build(:consent_given, :health_question_notes)

        expect(response.reasons_triage_needed).to eq(
          ["Health questions need triage"]
        )
      end
    end

    context "parent relationship is other and health questions indicate followup needed" do
      it "returns both check parental responsibility and notes need triage" do
        response = build(:consent_given, :health_question_notes, :from_granddad)

        expect(response.reasons_triage_needed).to include(
          "Health questions need triage"
        )
        expect(response.reasons_triage_needed).to include(
          "Check parental responsibility"
        )
      end
    end
  end

  describe "#from_consent_form!" do
    describe "the created consent object" do
      let(:session) { create(:session) }
      let(:consent_form) do
        create(:consent_form, session:, contact_method: :voice)
      end
      let(:patient_session) { create(:patient_session, session:) }

      subject(:consent) do
        Consent.from_consent_form!(consent_form, patient_session)
      end

      it "copies over attributes from consent_form" do
        expect(consent.reload).to(
          have_attributes(
            campaign: session.campaign,
            patient: patient_session.patient,
            consent_form:,
            parent_contact_method: consent_form.contact_method,
            parent_contact_method_other: consent_form.contact_method_other,
            parent_email: consent_form.parent_email,
            parent_name: consent_form.parent_name,
            parent_phone: consent_form.parent_phone,
            parent_relationship: consent_form.parent_relationship,
            parent_relationship_other: consent_form.parent_relationship_other,
            reason_for_refusal: consent_form.reason,
            reason_for_refusal_other: consent_form.reason_notes,
            response: consent_form.response,
            route: "website"
          )
        )
      end

      it "copies health answers from consent_form" do
        expect(consent.reload.health_answers.to_json).to eq(
          consent_form.health_answers.to_json
        )
      end

      it "runs the do_consent state transition" do
        expect { consent }.to change(patient_session, :state).from(
          "added_to_session"
        ).to("consent_given_triage_not_needed")
      end
    end
  end
end
