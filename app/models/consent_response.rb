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
#  recorded_at                 :datetime
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

class ConsentResponse < ApplicationRecord
  belongs_to :patient
  belongs_to :campaign

  enum :parent_relationship, %w[mother father guardian other], prefix: true
  enum :consent, %w[given refused], prefix: true
  enum :reason_for_refusal,
       %w[
         already_vaccinated
         will_be_vaccinated_elsewhere
         medical
         personal_choice
         other
       ],
       prefix: true
  enum :gp_response, %w[yes no dont_know]
  enum :route, %i[website phone paper in_person self_consent], prefix: "via"

  def triage_needed?
    consent_given? &&
      (parent_relationship_other? || health_questions_require_follow_up?)
  end

  def who_responded
    if parent_relationship == "other"
      parent_relationship_other
    else
      self.class.human_enum_name("parent_relationship", parent_relationship)
    end
  end

  def health_questions_require_follow_up?
    health_questions&.any? { |question| question["response"].downcase == "yes" }
  end

  def reasons_triage_needed
    reasons = []
    reasons << "Check parental responsibility" if parent_relationship_other?
    reasons << "Notes need triage" if health_questions_require_follow_up?
    reasons
  end
end
