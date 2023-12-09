# == Schema Information
#
# Table name: patient_sessions
#
#  id                       :bigint           not null, primary key
#  gillick_competence_notes :text
#  gillick_competent        :boolean
#  state                    :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  patient_id               :bigint           not null
#  session_id               :bigint           not null
#
# Indexes
#
#  index_patient_sessions_on_patient_id_and_session_id  (patient_id,session_id) UNIQUE
#  index_patient_sessions_on_session_id_and_patient_id  (session_id,patient_id) UNIQUE
#
FactoryBot.define do
  factory :patient_session do
    transient { user { create :user } }

    patient { create :patient }
    session { create :session }

    trait :added_to_session do
      state { "added_to_session" }
      patient { create :patient, consents: [] }
    end

    trait :consent_given_triage_not_needed do
      state { "consent_given_triage_not_needed" }
      patient { create :patient, :consent_given_triage_not_needed, session: }
    end

    trait :consent_given_triage_needed do
      state { "consent_given_triage_needed" }
      patient { create :patient, :consent_given_triage_needed, session: }
    end

    trait :consent_refused do
      state { "consent_refused" }
      patient { create :patient, :consent_refused, session: }
    end

    trait :consent_conflicting do
      state { "consent_refused" }
      patient { create :patient, :consent_conflicting, session: }
    end

    trait :triaged_ready_to_vaccinate do
      state { "triaged_ready_to_vaccinate" }
      patient { create :patient, :consent_given_triage_needed, session: }
      triage do
        [create(:triage, status: :ready_to_vaccinate, notes: "Ok to vaccinate")]
      end
    end

    trait :triaged_do_not_vaccinate do
      state { "triaged_do_not_vaccinate" }
      patient { create :patient, :consent_given_triage_needed, session: }
      triage { [create(:triage, status: :do_not_vaccinate, user:)] }
    end

    trait :triaged_kept_in_triage do
      state { "triaged_kept_in_triage" }
      patient { create :patient, :consent_given_triage_needed, session: }
      triage { [create(:triage, status: :needs_follow_up)] }
    end

    trait :did_not_need_triage do
      patient { create :patient, :consent_given_triage_not_needed, session: }
    end

    trait :unable_to_vaccinate do
      state { "unable_to_vaccinate" }
      patient { create :patient, :consent_given_triage_needed, session: }
      triage { [create(:triage, status: :ready_to_vaccinate, user:)] }

      after :create do |patient_session|
        create :vaccination_record,
               reason: :contraindications,
               administered: false,
               patient_session:
      end
    end

    trait :vaccinated do
      state { "vaccinated" }
      patient { create :patient, :consent_given_triage_needed, session: }
      triage { [create(:triage, status: :ready_to_vaccinate, user:)] }

      after :create do |patient_session|
        create :vaccination_record, administered: true, patient_session:
      end
    end

    trait :session_in_progress do
      session { create :session, :in_progress }
    end
  end
end
