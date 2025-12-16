# frozen_string_literal: true

module LoggingHelper
  def capture_log_tags
    captured = []

    original = SemanticLogger.method(:tagged)

    allow(SemanticLogger).to receive(:tagged) do |tags, &blk|
      captured << tags
      blk ? blk.call : nil
    end

    yield

    captured
  ensure
    allow(SemanticLogger).to receive(:tagged) do |*args, &blk|
      original.call(*args, &blk)
    end
  end
end

RSpec.configure { |config| config.include LoggingHelper }
