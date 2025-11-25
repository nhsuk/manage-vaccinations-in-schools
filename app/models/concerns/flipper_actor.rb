# frozen_string_literal: true

module FlipperActor
  extend ActiveSupport::Concern

  def flipper_id = "#{self.class.name}:#{to_param}"
end
