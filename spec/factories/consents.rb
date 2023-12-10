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
FactoryBot.define do
  factory :consent do
    transient do
      random { Random.new }
      health_questions_list { ["Is there anything else we should know?"] }
      # Allow caller to provide patient_session as a shortcut to produce
      # patient and campaign
      patient_session { nil }
    end

    patient { patient_session&.patient || create(:patient) }
    campaign { patient_session&.session&.campaign || create(:campaign) }
    response { "given" }
    parent_name { Faker::Name.name }
    parent_email { Faker::Internet.email(domain: "gmail.com") }
    parent_phone { Faker::PhoneNumber.cell_phone }
    address_line_1 { Faker::Address.street_address }
    address_line_2 do
      random.rand(1.0) > 0.8 ? Faker::Address.secondary_address : nil
    end
    address_town { Faker::Address.city }
    address_postcode { Faker::Address.postcode }
    route { "website" }
    recorded_at { Time.zone.now }

    health_questions do
      health_questions_list.map { |question| { question:, response: "no" } }
    end

    factory :consent_given do
      response { :given }
    end

    trait :refused do
      response { :refused }
      reason_for_refusal { :personal_choice }
      health_questions { [] }
    end

    factory :consent_refused do
      refused
    end

    trait :from_mum do
      parent_relationship { "mother" }
      parent_name do
        if patient.parent_relationship == "mother"
          patient.parent_name
        else
          "#{Faker::Name.female_first_name} #{patient.last_name}"
        end
      end
      parent_email do
        if patient.parent_relationship == "mother"
          patient.parent_email
        else
          "#{parent_name.downcase.gsub(" ", ".")}#{random.rand(100)}@gmail.com"
        end
      end
      parent_phone do
        if patient.parent_relationship == "mother"
          patient.parent_phone
        else
          Faker::PhoneNumber.cell_phone
        end
      end
    end

    trait :from_dad do
      parent_relationship { "father" }
      parent_name do
        if patient.parent_relationship == "father"
          patient.parent_name
        else
          "#{Faker::Name.male_first_name} #{patient.last_name}"
        end
      end
      parent_email do
        if patient.parent_relationship == "father"
          patient.parent_email
        else
          "#{parent_name.downcase.gsub(" ", ".")}#{random.rand(100)}@gmail.com"
        end
      end
      parent_phone do
        if patient.parent_relationship == "father"
          patient.parent_phone
        else
          Faker::PhoneNumber.cell_phone
        end
      end
    end

    trait :from_granddad do
      parent_relationship { "other" }
      parent_relationship_other { "Granddad" }
    end

    trait :health_question_notes do
      health_questions do
        health_questions_list.map do |question|
          if question == "Is there anything else we should know?"
            {
              question:,
              response: "yes",
              notes: "The child has a severe egg allergy"
            }
          else
            { question:, response: "no" }
          end
        end
      end
    end

    trait :no_contraindications do
      health_questions do
        health_questions_list.map { |question| { question:, response: "no" } }
      end
    end
  end
end
