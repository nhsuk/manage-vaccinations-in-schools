# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles
RSpec.configure do |config|
  config.before(:each, cis2: :enabled) do
    allow(Settings).to receive(:cis2).and_return(double(enabled: true))
  end

  config.before(:each, cis2: :disabled) do
    allow(Settings).to receive(:cis2).and_return(double(enabled: false))
  end
end
# rubocop:enable RSpec/VerifiedDoubles
