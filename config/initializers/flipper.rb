if Rails.env.test?
  require "flipper/adapters/pstore"
  require "flipper"

  Flipper.configure do |config|
    config.default do
      Flipper.new(Flipper::Adapters::PStore.new("tmp/flipper.test.pstore"))
    end
  end
end

# Flipper doesn't give us a way to set default values for features, no less
# using a proc.
FLIPPER_INITIALIZERS = {
  basic_auth: -> do
    if Rails.env.staging? || Rails.env.production?
      Flipper.enable(:basic_auth)
    else
      Flipper.disable(:basic_auth)
    end
  end,
  pilot_phase_1: -> do
    if Rails.env.staging? || Rails.env.production?
      Flipper.enable(:pilot_phase_1)
    else
      Flipper.disable(:pilot_phase_1)
    end
  end,
  parental_consent_jobs: -> do
    if Rails.env.staging? || Rails.env.production?
      Flipper.disable(:parental_consent_jobs)
    else
      Flipper.enable(:parental_consent_jobs)
    end
  end
}.freeze
