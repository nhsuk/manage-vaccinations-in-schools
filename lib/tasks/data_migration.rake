# frozen_string_literal: true

namespace :data_migration do
  desc "Remove clinic session notifications which are no longer used."
  task delete_clinic_session_notifications: :environment do
    SessionNotification.where(type: [1, 2]).delete_all
  end

  desc "Set disease types on vaccination records."
  task set_disease_types: :environment do
    VaccinationRecord
      .includes(:vaccine)
      .where(disease_types: nil)
      .find_each do |vaccination_record|
        disease_types =
          vaccination_record.vaccine&.disease_types ||
            vaccination_record.programme.disease_types
        vaccination_record.update_columns(disease_types:)
      end
  end
end
