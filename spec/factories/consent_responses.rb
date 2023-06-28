# == Schema Information
#
# Table name: consent_responses
#
#  id                          :bigint           not null, primary key
#  address_line_1              :text
#  address_line_2              :text
#  address_postcode            :text
#  address_town                :text
#  childs_common_name          :text
#  childs_dob                  :date
#  childs_name                 :text
#  consent                     :integer
#  gp_name                     :text
#  gp_response                 :integer
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
#  route                       :integer          not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  campaign_id                 :bigint           not null
#  patient_id                  :bigint           not null
#
# Indexes
#
#  index_consent_responses_on_campaign_id  (campaign_id)
#  index_consent_responses_on_patient_id   (patient_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id)
#  fk_rails_...  (patient_id => patients.id)
#
FactoryBot.define do
  factory :consent_response do
    patient { create :patient }
    campaign { create :campaign }
    consent { "given" }
    address_line_1 { Faker::Address.street_address }
    address_line_2 do
      Random.rand(1.0) > 0.8 ? Faker::Address.secondary_address : nil
    end
    address_town { Faker::Address.city }
    address_postcode { Faker::Address.postcode }
    route { "website" }

    health_questions do
      [
        {
          question:
            "Does the child have a disease or treatment that severely affects their immune system?",
          response: "No"
        },
        {
          question:
            "Is anyone in your household having treatment that severely affects their immune system?",
          response: "No"
        },
        {
          question: "Has your child been diagnosed with asthma?",
          response: "No"
        },
        {
          question:
            "Has your child been admitted to intensive care because of a severe egg allergy?",
          response: "No"
        },
        { question: "Is there anything else we should know?", response: "No" }
      ]
    end
  end
end
