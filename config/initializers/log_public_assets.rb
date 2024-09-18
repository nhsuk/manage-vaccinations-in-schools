# frozen_string_literal: true

return unless Rails.env.development?

module ActionDispatch
  class FileHandler
    def attempt(env)
      result = super(env)

      if result
        request = Rack::Request.new env
        Rails.logger.debug("Serving static asset: #{request.path_info}")
      end

      result
    end
  end
end
