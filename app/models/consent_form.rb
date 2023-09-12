# == Schema Information
#
# Table name: consent_forms
#
#  id                        :bigint           not null, primary key
#  common_name               :text
#  contact_injection         :boolean
#  contact_method            :integer
#  contact_method_other      :text
#  date_of_birth             :date
#  first_name                :text
#  last_name                 :text
#  parent_email              :string
#  parent_name               :string
#  parent_phone              :string
#  parent_relationship       :integer
#  parent_relationship_other :string
#  reason                    :integer
#  reason_notes              :text
#  recorded_at               :datetime
#  response                  :integer
#  use_common_name           :boolean
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  session_id                :bigint           not null
#
# Indexes
#
#  index_consent_forms_on_session_id  (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (session_id => sessions.id)
#

class ConsentForm < ApplicationRecord
  attr_accessor :form_step, :is_this_their_school

  audited

  belongs_to :session

  enum :parent_relationship, %w[mother father guardian other], prefix: true
  enum :contact_method, %w[text voice other], prefix: true
  enum :response, %w[given refused not_provided], prefix: "consent"
  enum :reason,
       %w[
         contains_gelatine
         already_received
         given_elsewhere
         medical_reasons
         personal_choice
         other
       ],
       prefix: "refused_because"

  with_options on: :update do
    with_options if: -> { required_for_step?(:name) } do
      validates :first_name, presence: true
      validates :last_name, presence: true
      validates :use_common_name, inclusion: { in: [true, false] }
      validates :common_name, presence: true, if: :use_common_name?
    end

    with_options if: -> { required_for_step?(:date_of_birth) } do
      validates :date_of_birth,
                presence: true,
                comparison: {
                  less_than: Time.zone.today,
                  greater_than_or_equal_to: 22.years.ago.to_date,
                  less_than_or_equal_to: 3.years.ago.to_date
                }
    end

    with_options if: -> { required_for_step?(:school, exact: true) } do
      validates :is_this_their_school,
                presence: true,
                inclusion: {
                  in: %w[yes no]
                }
    end

    with_options if: -> { required_for_step?(:parent) } do
      validates :parent_name, presence: true
      validates :parent_relationship, presence: true
      validates :parent_relationship_other,
                presence: true,
                if: :parent_relationship_other?
      validates :parent_email, presence: true
      validates :contact_method_other,
                presence: true,
                if: :contact_method_other?
    end

    with_options if: -> { required_for_step?(:consent) } do
      validates :response, presence: true
    end

    with_options if: -> { required_for_step?(:reason) } do
      validates :reason, presence: true
    end

    with_options if: -> { required_for_step?(:injection) } do
      validates :contact_injection, presence: true
    end
  end

  def full_name
    [first_name, last_name].join(" ")
  end

  def eligible_for_injection?
    !refused_because_given_elsewhere? && !refused_because_already_received?
  end

  def form_steps
    if consent_refused? && eligible_for_injection?
      %i[name date_of_birth school parent consent reason injection]
    elsif consent_refused?
      %i[name date_of_birth school parent consent reason]
    else
      %i[name date_of_birth school parent consent]
    end
  end

  private

  def required_for_step?(step, exact: false)
    # Exact means that the form_step must match the step
    return false if exact && form_step != step

    # Step can't be required if it's not in the current form_steps list
    return false unless step.in?(form_steps)

    # All fields are required if no form_step is set
    return true if form_step.nil?

    # Otherwise, all fields from previous and current steps are required
    return true if form_steps.index(step) <= form_steps.index(form_step)

    false
  end
end
