if Rails.env.test?
  require "flipper/adapters/memory"
  require "flipper"

  Flipper.configure do |config|
    config.default { Flipper.new(Flipper::Adapters::Memory.new) }
  end
end
