# frozen_string_literal: true

class StatusUpdaterJob
  include Sidekiq::Job
  include Sidekiq::Throttled::Job

  sidekiq_options queue: :cache
  sidekiq_throttle concurrency: {
                     limit: 1,
                     key_suffix: ->(patient_id) do
                       patient_id ? patient_id.to_s : "all"
                     end
                   }

  def perform(patient_id = nil)
    academic_years = [AcademicYear.current, AcademicYear.pending].uniq

    if patient_id
      if (patient = Patient.find_by(id: patient_id))
        StatusUpdater.call(patient:, academic_years:)
      end
    else
      StatusUpdater.call(academic_years:)
    end
  end
end
