# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_form_programmes
#
#  id              :bigint           not null, primary key
#  response        :integer
#  vaccine_methods :integer          default([]), not null, is an Array
#  consent_form_id :bigint           not null
#  programme_id    :bigint           not null
#
# Indexes
#
#  idx_on_programme_id_consent_form_id_2113cb7f37    (programme_id,consent_form_id) UNIQUE
#  index_consent_form_programmes_on_consent_form_id  (consent_form_id)
#
# Foreign Keys
#
#  fk_rails_...  (consent_form_id => consent_forms.id)
#  fk_rails_...  (programme_id => programmes.id)
#
FactoryBot.define do
  factory :consent_form_programmes do
    consent_form
    programme

    trait :given do
      response { "given" }
      vaccine_methods { %w[injection] }
    end

    trait :refused do
      response { "refused" }
      vaccine_methods { [] }
    end
  end
end
