# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_sessions
#
#  id                 :bigint           not null, primary key
#  active             :boolean          default(FALSE), not null
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
      user { association :user }
      patient_attributes { {} }
      session_attributes { {} }
    end

    session { association :session, **session_attributes }
    patient { association :patient, session:, **patient_attributes }
    active { session&.active? }
    created_by { user }

    trait :active do
      active { true }
    end

    trait :draft do
      active { false }
    end

    trait :added_to_session do
      active
      patient { create :patient, consents: [] }
    end

    trait :consent_given_triage_not_needed do
      active
      patient { create :patient, :consent_given_triage_not_needed, session: }
    end

    trait :consent_given_triage_needed do
      active
      patient { create :patient, :consent_given_triage_needed, session: }
    end

    trait :consent_refused do
      active
      patient { create :patient, :consent_refused, session: }
    end

    trait :consent_refused_with_notes do
      active
      patient { create :patient, :consent_refused_with_notes, session: }
    end

    trait :consent_conflicting do
      active
      patient { create :patient, :consent_conflicting, session: }
    end

    trait :triaged_ready_to_vaccinate do
      active
      patient { create :patient, :consent_given_triage_needed, session: }
      triage do
        [
          association(
            :triage,
            :ready_to_vaccinate,
            notes: "Okay to vaccinate",
            patient_session: instance,
            performed_by: user
          )
        ]
      end
    end

    trait :triaged_do_not_vaccinate do
      active
      patient { create :patient, :consent_given_triage_needed, session: }
      triage do
        [
          association(
            :triage,
            :do_not_vaccinate,
            patient_session: instance,
            performed_by: user
          )
        ]
      end
    end

    trait :triaged_kept_in_triage do
      active
      patient { create :patient, :consent_given_triage_needed, session: }
      triage do
        [
          association(
            :triage,
            :needs_follow_up,
            patient_session: instance,
            performed_by: user
          )
        ]
      end
    end

    trait :delay_vaccination do
      active
      patient { create :patient, :consent_given_triage_needed, session: }
      triage do
        [
          association(
            :triage,
            :delay_vaccination,
            patient_session: instance,
            performed_by: user
          )
        ]
      end

      vaccination_records do
        [
          association(
            :vaccination_record,
            :not_administered,
            patient_session: instance,
            performed_by: user,
            reason: :absent_from_school
          )
        ]
      end
    end

    trait :did_not_need_triage do
      active
      patient { create :patient, :consent_given_triage_not_needed, session: }
    end

    trait :unable_to_vaccinate do
      active
      patient { create :patient, :consent_given_triage_needed, session: }
      triage do
        [
          association(
            :triage,
            :ready_to_vaccinate,
            patient_session: instance,
            performed_by: user
          )
        ]
      end
      vaccination_records do
        [
          association(
            :vaccination_record,
            :not_administered,
            patient_session: instance,
            performed_by: user,
            reason: :already_had
          )
        ]
      end
    end

    trait :unable_to_vaccinate_not_gillick_competent do
      active

      gillick_assessment do
        create :gillick_assessment, :not_competent, patient_session: instance
      end

      patient { create :patient, :consent_given_triage_needed, session: }
      triage do
        [
          association(
            :triage,
            :ready_to_vaccinate,
            patient_session: instance,
            performed_by: user
          )
        ]
      end

      vaccination_records do
        [
          association(
            :vaccination_record,
            :not_administered,
            patient_session: instance,
            performed_by: user,
            reason: :already_had
          )
        ]
      end
    end

    trait :vaccinated do
      active
      patient { create :patient, :consent_given_triage_needed, session: }
      triage do
        [
          association(
            :triage,
            :ready_to_vaccinate,
            patient_session: instance,
            performed_by: user
          )
        ]
      end
      vaccination_records do
        [
          association(
            :vaccination_record,
            patient_session: instance,
            performed_by: user
          )
        ]
      end
    end

    trait :session_in_progress do
      active
      session { association :session, :in_progress, **session_attributes }
    end

    trait :not_gillick_competent do
      active
      gillick_assessment do
        create :gillick_assessment, :not_competent, patient_session: instance
      end
    end
  end
end
