# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_sessions
#
#  id                 :bigint           not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_user_id :bigint
#  patient_id         :bigint           not null
#  session_id         :bigint           not null
#
# Indexes
#
#  index_patient_sessions_on_created_by_user_id         (created_by_user_id)
#  index_patient_sessions_on_patient_id_and_session_id  (patient_id,session_id) UNIQUE
#  index_patient_sessions_on_session_id_and_patient_id  (session_id,patient_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (created_by_user_id => users.id)
#
FactoryBot.define do
  factory :patient_session do
    transient do
      programme { association :programme }
      team { session.team }
    end

    session { association :session, programme: }
    patient { association :patient, team:, school: session.location }
    created_by

    trait :added_to_session

    trait :consent_given_triage_not_needed do
      patient do
        association :patient,
                    :consent_given_triage_not_needed,
                    programme:,
                    team:,
                    school: session.location
      end
    end

    trait :consent_given_triage_needed do
      patient do
        association :patient,
                    :consent_given_triage_needed,
                    programme:,
                    team:,
                    school: session.location
      end
    end

    trait :consent_refused do
      patient do
        association :patient,
                    :consent_refused,
                    programme:,
                    team:,
                    school: session.location
      end
    end

    trait :consent_refused_with_notes do
      patient do
        association :patient,
                    :consent_refused_with_notes,
                    programme:,
                    team:,
                    school: session.location
      end
    end

    trait :consent_conflicting do
      patient do
        association :patient,
                    :consent_conflicting,
                    programme:,
                    team:,
                    school: session.location
      end
    end

    trait :triaged_ready_to_vaccinate do
      patient do
        association :patient,
                    :consent_given_triage_needed,
                    programme:,
                    team:,
                    school: session.location
      end

      triages do
        [
          association(
            :triage,
            :ready_to_vaccinate,
            patient_session: instance,
            programme:,
            notes: "Okay to vaccinate",
            performed_by: created_by
          )
        ]
      end
    end

    trait :triaged_do_not_vaccinate do
      patient do
        association :patient,
                    :consent_given_triage_needed,
                    programme:,
                    team:,
                    school: session.location
      end

      triages do
        [
          association(
            :triage,
            :do_not_vaccinate,
            patient_session: instance,
            programme:,
            performed_by: created_by
          )
        ]
      end
    end

    trait :triaged_kept_in_triage do
      patient do
        association :patient,
                    :consent_given_triage_needed,
                    programme:,
                    team:,
                    school: session.location
      end

      triages do
        [
          association(
            :triage,
            :needs_follow_up,
            patient_session: instance,
            programme:,
            performed_by: created_by
          )
        ]
      end
    end

    trait :delay_vaccination do
      patient do
        association :patient,
                    :consent_given_triage_needed,
                    programme:,
                    team:,
                    school: session.location
      end

      triages do
        [
          association(
            :triage,
            :delay_vaccination,
            patient_session: instance,
            programme:,
            performed_by: created_by
          )
        ]
      end

      vaccination_records do
        [
          association(
            :vaccination_record,
            :not_administered,
            patient_session: instance,
            programme:,
            performed_by: created_by,
            reason: :absent_from_school
          )
        ]
      end
    end

    trait :did_not_need_triage do
      patient do
        association :patient,
                    :consent_given_triage_not_needed,
                    programme:,
                    team:,
                    school: session.location
      end
    end

    trait :unable_to_vaccinate do
      patient do
        association :patient,
                    :consent_given_triage_needed,
                    programme:,
                    team:,
                    school: session.location
      end

      triages do
        [
          association(
            :triage,
            :ready_to_vaccinate,
            patient_session: instance,
            programme:,
            performed_by: created_by
          )
        ]
      end

      vaccination_records do
        [
          association(
            :vaccination_record,
            :not_administered,
            patient_session: instance,
            programme:,
            performed_by: created_by,
            reason: :already_had
          )
        ]
      end
    end

    trait :unable_to_vaccinate_not_gillick_competent do
      gillick_assessment do
        association :gillick_assessment,
                    :not_competent,
                    patient_session: instance
      end

      patient do
        association :patient,
                    :consent_given_triage_needed,
                    programme:,
                    team:,
                    school: session.location
      end

      triages do
        [
          association(
            :triage,
            :ready_to_vaccinate,
            patient_session: instance,
            programme:,
            performed_by: created_by
          )
        ]
      end

      vaccination_records do
        [
          association(
            :vaccination_record,
            :not_administered,
            patient_session: instance,
            programme:,
            performed_by: created_by,
            reason: :already_had
          )
        ]
      end
    end

    trait :vaccinated do
      patient do
        association :patient,
                    :consent_given_triage_needed,
                    programme:,
                    team:,
                    school: session.location
      end

      triages do
        [
          association(
            :triage,
            :ready_to_vaccinate,
            patient_session: instance,
            programme:,
            performed_by: created_by
          )
        ]
      end

      vaccination_records do
        [
          association(
            :vaccination_record,
            patient_session: instance,
            programme:,
            performed_by: created_by
          )
        ]
      end
    end

    trait :session_in_progress do
      session { association :session, :today, programme: }
    end

    trait :not_gillick_competent do
      gillick_assessment do
        association :gillick_assessment,
                    :not_competent,
                    patient_session: instance
      end
    end
  end
end
