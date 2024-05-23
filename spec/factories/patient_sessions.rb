# == Schema Information
#
# Table name: patient_sessions
#
#  id                                  :bigint           not null, primary key
#  gillick_competence_notes            :text
#  gillick_competent                   :boolean
#  state                               :string
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  gillick_competence_assessor_user_id :bigint
#  patient_id                          :bigint           not null
#  session_id                          :bigint           not null
#
# Indexes
#
#  index_patient_sessions_on_gillick_competence_assessor_user_id  (gillick_competence_assessor_user_id)
#  index_patient_sessions_on_patient_id_and_session_id            (patient_id,session_id) UNIQUE
#  index_patient_sessions_on_session_id_and_patient_id            (session_id,patient_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (gillick_competence_assessor_user_id => users.id)
#
FactoryBot.define do
  factory :patient_session do
    transient do
      campaign { create :campaign }
      user { create :user }
    end

    patient { create :patient, session: }
    session { create(:session, campaign:) }

    trait :added_to_session do
      patient { create :patient, consents: [] }
    end

    trait :consent_given_triage_not_needed do
      patient { create :patient, :consent_given_triage_not_needed, session: }
    end

    trait :consent_given_triage_needed do
      patient { create :patient, :consent_given_triage_needed, session: }
    end

    trait :consent_refused do
      patient { create :patient, :consent_refused, session: }
    end

    trait :consent_refused_with_notes do
      patient { create :patient, :consent_refused_with_notes, session: }
    end

    trait :consent_conflicting do
      patient { create :patient, :consent_conflicting, session: }
    end

    trait :triaged_ready_to_vaccinate do
      patient { create :patient, :consent_given_triage_needed, session: }
      triage do
        create_list(
          :triage,
          1,
          status: :ready_to_vaccinate,
          notes: "Ok to vaccinate",
          user:,
          patient_session: instance
        )
      end
    end

    trait :triaged_do_not_vaccinate do
      patient { create :patient, :consent_given_triage_needed, session: }
      triage do
        [
          create(
            :triage,
            status: :do_not_vaccinate,
            user:,
            patient_session: instance
          )
        ]
      end
    end

    trait :triaged_kept_in_triage do
      patient { create :patient, :consent_given_triage_needed, session: }
      triage do
        [
          create(
            :triage,
            status: :needs_follow_up,
            user:,
            patient_session: instance
          )
        ]
      end
    end

    trait :delay_vaccination do
      patient { create :patient, :consent_given_triage_needed, session: }
      triage do
        [
          create(
            :triage,
            status: :delay_vaccination,
            user:,
            patient_session: instance
          )
        ]
      end

      vaccination_records do
        create_list(
          :vaccination_record,
          1,
          reason: :absent_from_school,
          administered: false,
          user:,
          patient_session: instance
        )
      end
    end

    trait :did_not_need_triage do
      patient { create :patient, :consent_given_triage_not_needed, session: }
    end

    trait :unable_to_vaccinate do
      patient { create :patient, :consent_given_triage_needed, session: }
      triage do
        [
          create(
            :triage,
            status: :ready_to_vaccinate,
            user:,
            patient_session: instance
          )
        ]
      end
      vaccination_records do
        create_list(
          :vaccination_record,
          1,
          reason: :already_had,
          administered: false,
          user:,
          patient_session: instance
        )
      end
    end

    trait :unable_to_vaccinate_not_gillick_competent do
      gillick_competent { false }
      gillick_competence_notes { "Assessed as not gillick competent" }
      gillick_competence_assessor { user }

      patient { create :patient, :consent_given_triage_needed, session: }
      triage do
        [
          create(
            :triage,
            status: :ready_to_vaccinate,
            user:,
            patient_session: instance
          )
        ]
      end

      vaccination_records do
        create_list(
          :vaccination_record,
          1,
          reason: :already_had,
          administered: false,
          user:,
          patient_session: instance
        )
      end
    end

    trait :vaccinated do
      patient { create :patient, :consent_given_triage_needed, session: }
      triage do
        [
          create(
            :triage,
            status: :ready_to_vaccinate,
            user:,
            patient_session: instance
          )
        ]
      end
      vaccination_records do
        create_list(
          :vaccination_record,
          1,
          administered: true,
          user:,
          patient_session: instance
        )
      end
    end

    trait :session_in_progress do
      session { create :session, :in_progress }
    end

    trait :after_gillick_competence_assessed do
      gillick_competent { true }
      gillick_competence_notes { "Assessed as gillick competent" }
      gillick_competence_assessor { create :user }
    end

    trait :not_gillick_competent do
      gillick_competent { false }
      gillick_competence_notes { "Assessed as not gillick competent" }
      gillick_competence_assessor { create :user }
    end
  end
end
