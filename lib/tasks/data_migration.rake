# frozen_string_literal: true

namespace :data_migration do
  desc "Unset performed at time on imported vaccination records if midnight"
  task unset_vaccination_record_performed_at_time: :environment do
    VaccinationRecord
      .sourced_from_historical_upload
      .where("performed_at_time = '00:00:00'")
      .update_all(performed_at_time: nil)
  end
end
