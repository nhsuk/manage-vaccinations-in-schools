# == Schema Information
#
# Table name: consents
#
#  id                          :bigint           not null, primary key
#  address_line_1              :text
#  address_line_2              :text
#  address_postcode            :text
#  address_town                :text
#  childs_common_name          :text
#  childs_dob                  :date
#  childs_name                 :text
#  gp_name                     :text
#  gp_response                 :integer
#  health_answers              :jsonb
#  health_questions            :jsonb
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
      health_responses = [
        {
          question:
            "Does the child have a disease or treatment that severely affects their immune system?",
          response: "yes"
        }
      ]
      response =
        build(
          :consent_given,
          parent_relationship: :mother,
          health_questions: health_responses
        )

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
end
