# frozen_string_literal: true

module LoggingHelper
  def capture_log_tags
    captured = []

    allow(SemanticLogger).to receive(
      :tagged
    ).and_wrap_original do |original, **tags, &blk|
      captured << tags
      original.call(**tags, &blk)
    end

    yield

    captured
  end
end

RSpec.configure { |config| config.include LoggingHelper }
