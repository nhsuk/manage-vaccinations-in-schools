# frozen_string_literal: true

class ImmunisationsAPIJob
  include Sidekiq::Job
  include Sidekiq::Throttled::Job

  sidekiq_options queue: :immunisations_api
  sidekiq_throttle_as :immunisations_api

  def job_id = Sidekiq::Context.current["jid"]
end
