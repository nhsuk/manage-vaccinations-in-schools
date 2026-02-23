# frozen_string_literal: true

describe UserSessionLogger do
  subject(:log_content) { log_output.string }

  let(:middleware) { described_class.new(app) }
  let(:app) do
    lambda do |_env|
      Rails.logger.info("Processing request")
      [200, {}, ["OK"]]
    end
  end
  let(:log_output) { StringIO.new }
  let(:env) { { "rack.session" => session } }
  let(:logger) { ActiveSupport::TaggedLogging.new(Logger.new(log_output)) }

  let(:session) do
    instance_double(ActionDispatch::Request::Session, id: session_id)
  end
  let(:session_id) do
    instance_double(Rack::Session::SessionId, public_id: user_session_id)
  end

  before { allow(Rails).to receive(:logger).and_return(logger) }

  describe "#call" do
    before do
      middleware.call(env)
    rescue StandardError => e
      raise unless e.message == "Intentional Error for Testing"
    end

    context "when session exists with an id" do
      let(:user_session_id) { "abcdefghi" }

      it { should include("Processing request") }
      it { should include('user_session_id: "abcdefghi"') }
    end

    context "when there is no session" do
      let(:session) { nil }

      it { should include("Processing request") }
      it { should_not include("user_session_id") }
    end

    context "when an exception occurs in the app" do
      let(:user_session_id) { "rstuvwxyz" }

      let(:app) do
        lambda do |_env|
          Rails.logger.error("An error occurred")
          raise StandardError, "Intentional Error for Testing"
        end
      end

      it { should include('user_session_id: "rstuvwxyz"') }
      it { should include("An error occurred") }
    end
  end
end
