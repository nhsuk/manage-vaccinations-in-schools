# frozen_string_literal: true

return unless Rails.env.development?

require Rails.root.join("lib/core_extensions/action_dispatch/file_handler.rb")

module ActionDispatch
  class FileHandler
    prepend CoreExtensions::ActionDispatch::FileHandler
  end
end
