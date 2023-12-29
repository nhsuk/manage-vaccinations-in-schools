if Rails.env.test?
  require "flipper/adapters/pstore"
  require "flipper"

  Flipper.configure do |config|
    config.default do
      Flipper.new(Flipper::Adapters::PStore.new("tmp/flipper.test.pstore"))
    end
  end
end
