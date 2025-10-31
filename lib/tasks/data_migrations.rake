# frozen_string_literal: true

namespace :data_migrations do
  desc "Set without_gelatine value on all consents to ensure they are valid"
  task set_consent_without_gelatine: :environment do
    flu_programme = Programme.flu.sole

    Consent
      .response_given
      .where(without_gelatine: nil)
      .find_each do |consent|
        is_flu = consent.programme_id == flu_programme.id
        consented_to_nasal = consent.vaccine_methods.include?("nasal")

        without_gelatine = is_flu && !consented_to_nasal
        consent.update_columns(without_gelatine:)
      end
  end

  desc "Set without_gelatine value on all triages to ensure they are valid"
  task set_triage_without_gelatine: :environment do
    flu_programme = Programme.flu.sole

    Triage
      .safe_to_vaccinate
      .where(without_gelatine: nil)
      .find_each do |triage|
        is_flu = triage.programme_id == flu_programme.id
        triaged_as_injection = triage.vaccine_method == "injection"

        without_gelatine = is_flu && triaged_as_injection
        triage.update_columns(without_gelatine:)
      end
  end
end
