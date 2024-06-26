# frozen_string_literal: true

module CoreExtensions
  module ActionDispatch
    module FileHandler
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
end
