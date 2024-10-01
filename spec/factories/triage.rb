# frozen_string_literal: true

# == Schema Information
#
# Table name: triage
#
#  id                   :bigint           not null, primary key
#  notes                :text             default(""), not null
#  status               :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  patient_session_id   :bigint           not null
#  performed_by_user_id :bigint           not null
#  programme_id         :bigint           not null
#
# Indexes
#
#  index_triage_on_patient_session_id    (patient_session_id)
#  index_triage_on_performed_by_user_id  (performed_by_user_id)
#  index_triage_on_programme_id          (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#
FactoryBot.define do
  factory :triage do
    transient do
      session { association :session, programme: }
      team { session.team }
      patient { association :patient, team: }
    end

    programme
    patient_session { association :patient_session, patient:, session: }

    performed_by

    notes { "" }
    status { :ready_to_vaccinate }

    traits_for_enum :status
  end
end
