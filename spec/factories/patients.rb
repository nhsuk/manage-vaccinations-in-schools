# frozen_string_literal: true

# == Schema Information
#
# Table name: patients
#
#  id                        :bigint           not null, primary key
#  address_line_1            :string
#  address_line_2            :string
#  address_postcode          :string
#  address_town              :string
#  birth_academic_year       :integer          not null
#  date_of_birth             :date             not null
#  date_of_death             :date
#  date_of_death_recorded_at :datetime
#  family_name               :string           not null
#  gender_code               :integer          default("not_known"), not null
#  given_name                :string           not null
#  home_educated             :boolean
#  invalidated_at            :datetime
#  nhs_number                :string
#  pending_changes           :jsonb            not null
#  preferred_family_name     :string
#  preferred_given_name      :string
#  registration              :string
#  restricted_at             :datetime
#  updated_from_pds_at       :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  cohort_id                 :bigint
#  gp_practice_id            :bigint
#  organisation_id           :bigint
#  school_id                 :bigint
#
# Indexes
#
#  index_patients_on_cohort_id            (cohort_id)
#  index_patients_on_family_name_trigram  (family_name) USING gin
#  index_patients_on_given_name_trigram   (given_name) USING gin
#  index_patients_on_gp_practice_id       (gp_practice_id)
#  index_patients_on_names_family_first   (family_name,given_name)
#  index_patients_on_names_given_first    (given_name,family_name)
#  index_patients_on_nhs_number           (nhs_number) UNIQUE
#  index_patients_on_organisation_id      (organisation_id)
#  index_patients_on_school_id            (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (cohort_id => cohorts.id)
#  fk_rails_...  (gp_practice_id => locations.id)
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (school_id => locations.id)
#

require_relative "../../lib/faker/address"

FactoryBot.define do
  sequence :nhs_number_counter, 1

  factory :patient do
    transient do
      parents { [] }
      performed_by { association(:user) }
      programme { session&.programmes&.first }
      session { nil }
      year_group { nil }
      location_name { nil }
      in_attendance { false }
    end

    organisation do
      session&.organisation ||
        association(:organisation, programmes: [programme].compact)
    end
    cohort { Cohort.find_or_create_by!(birth_academic_year:, organisation:) }

    nhs_number do
      # Prevents duplicate NHS numbers by sequencing and appending a check
      # digit. See Faker's implementation for details:
      # https://github.com/faker-ruby/faker/blob/6ba06393f47d4018b5fdbdaaa04eb9891ae5fb55/lib/faker/default/national_health_service.rb
      base = 999_000_000 + generate(:nhs_number_counter)
      sum = base.to_s.chars.map.with_index { |d, i| d.to_i * (10 - i) }.sum
      check_digit = (11 - (sum % 11)) % 11
      redo if check_digit == 10 # Retry if check digit is 10, which is invalid

      "#{base}#{check_digit}"
    end

    given_name { Faker::Name.first_name }
    family_name { Faker::Name.last_name }

    date_of_birth do
      if year_group
        academic_year_start = Date.new(Date.current.academic_year, 9, 1)
        start_date = academic_year_start - (5 + year_group).years
        end_date = start_date + 1.year - 1.day
        Faker::Date.between(from: end_date, to: start_date)
      else
        Faker::Date.birthday(min_age: 7, max_age: 16)
      end
    end
    birth_academic_year { date_of_birth.academic_year }
    registration { Faker::Alphanumeric.alpha(number: 2).upcase }

    school { session.location if session&.location&.school? }
    home_educated { school.present? ? nil : false }

    address_line_1 { Faker::Address.street_address }
    address_line_2 { Faker::Address.secondary_address }
    address_town { Faker::Address.city }
    address_postcode { Faker::Address.uk_postcode }

    parent_relationships do
      parents.map do |parent|
        association(:parent_relationship, patient: instance, parent:)
      end
    end

    after(:create) do |patient, evaluator|
      if evaluator.session
        patient_session =
          patient.patient_sessions.find_or_create_by!(
            session: evaluator.session
          )

        if evaluator.in_attendance
          create(:session_attendance, :present, patient_session:)
        end
      end
    end

    trait :in_attendance do
      in_attendance { true }
    end

    trait :home_educated do
      school { nil }
      home_educated { true }
    end

    trait :deceased do
      date_of_death { Date.current }
      date_of_death_recorded_at { Time.current }
    end

    trait :invalidated do
      invalidated_at { Time.current }
    end

    trait :restricted do
      restricted_at { Time.current }
    end

    trait :consent_request_sent do
      after(:create) do |patient, context|
        create(
          :consent_notification,
          :request,
          patient:,
          programme: context.programme,
          sent_at: 1.week.ago
        )
      end
    end

    trait :initial_consent_reminder_sent do
      after(:create) do |patient, context|
        create(
          :consent_notification,
          :initial_reminder,
          patient:,
          programme: context.programme
        )
      end
    end

    trait :consent_given_triage_not_needed do
      consents do
        [
          association(
            :consent,
            :given,
            :from_mum,
            patient: instance,
            organisation:,
            programme:
          )
        ]
      end
    end

    trait :consent_given_triage_needed do
      consents do
        [
          association(
            :consent,
            :given,
            :from_mum,
            :health_question_notes,
            patient: instance,
            programme:,
            organisation:
          )
        ]
      end
    end

    trait :consent_refused do
      consents do
        [
          association(
            :consent,
            :refused,
            :from_mum,
            patient: instance,
            organisation:,
            programme:
          )
        ]
      end
    end

    trait :consent_refused_with_notes do
      consents do
        [
          association(
            :consent,
            :refused,
            :from_mum,
            patient: instance,
            organisation:,
            programme:,
            reason_for_refusal: "already_vaccinated",
            notes: "Already had the vaccine at the GP"
          )
        ]
      end
    end

    trait :consent_conflicting do
      consents do
        [
          association(
            :consent,
            :refused,
            :from_mum,
            patient: instance,
            organisation:,
            programme:
          ),
          association(
            :consent,
            :given,
            :from_dad,
            patient: instance,
            organisation:,
            programme:
          )
        ]
      end
    end

    trait :consent_not_provided do
      consents do
        [
          association(
            :consent,
            :not_provided,
            :from_mum,
            patient: instance,
            organisation:,
            programme:
          )
        ]
      end
    end

    trait :triage_ready_to_vaccinate do
      consent_given_triage_needed

      triages do
        [
          association(
            :triage,
            :ready_to_vaccinate,
            patient: instance,
            performed_by:,
            programme:,
            organisation:,
            notes: "Okay to vaccinate"
          )
        ]
      end
    end

    trait :triage_do_not_vaccinate do
      triages do
        [
          association(
            :triage,
            :do_not_vaccinate,
            patient: instance,
            performed_by:,
            programme:,
            organisation:,
            notes: "Do not vaccinate"
          )
        ]
      end
    end

    trait :triage_needs_follow_up do
      triages do
        [
          association(
            :triage,
            :needs_follow_up,
            patient: instance,
            performed_by:,
            programme:,
            organisation:,
            notes: "Needs follow up"
          )
        ]
      end
    end

    trait :triage_delay_vaccination do
      triages do
        [
          association(
            :triage,
            :delay_vaccination,
            patient: instance,
            performed_by:,
            programme:,
            organisation:,
            notes: "Delay vaccination"
          )
        ]
      end
    end

    trait :vaccinated do
      vaccination_records do
        [
          if session
            association(
              :vaccination_record,
              patient: instance,
              programme:,
              session:,
              location_name:
            )
          else
            association(:vaccination_record, patient: instance, programme:)
          end
        ]
      end
    end
  end
end
