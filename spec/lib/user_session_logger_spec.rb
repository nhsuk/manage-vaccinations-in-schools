# frozen_string_literal: true

describe UserSessionLogger do
  subject(:middleware) { described_class.new(app) }

  let(:app) do
    lambda do |_env|
      Rails.logger.info("Processing request")
      [200, {}, ["OK"]]
    end
  end
  let(:env) { { "rack.session" => session } }
  let(:log_output) { StringIO.new }
  let(:logger) { ActiveSupport::TaggedLogging.new(Logger.new(log_output)) }

  before { allow(Rails).to receive(:logger).and_return(logger) }

  describe "#call" do
    context "when session exists with an id" do
      let(:session) do
        instance_double(ActionDispatch::Request::Session, id: session_id)
      end
      let(:session_id) do
        instance_double(Rack::Session::SessionId, public_id: "abcdefghi")
      end

      it "tags the logger with the session public_id" do
        middleware.call(env)

        log_content = log_output.string
        expect(log_content).to include('user_session_id: "abcdefghi"')
        expect(log_content).to include("Processing request")
      end

      it "returns the app response" do
        expect(middleware.call(env)).to eq([200, {}, ["OK"]])
      end
    end

    context "when there is no session" do
      let(:session) { nil }

      it "does not add a user session id tag" do
        middleware.call(env)

        log_content = log_output.string
        expect(log_content).not_to include("user_session_id")
        expect(log_content).to include("Processing request")
      end
    end

    context "when an exception occurs in the app" do
      let(:session) do
        instance_double(ActionDispatch::Request::Session, id: session_id)
      end
      let(:session_id) do
        instance_double(Rack::Session::SessionId, public_id: "rstuvwxyz")
      end
      let(:app) do
        lambda do |_env|
          Rails.logger.error("An error occurred")
          raise StandardError, "Something went wrong"
        end
      end

      it "still tags the logger before the exception propagates" do
        expect { middleware.call(env) }.to raise_error(
          StandardError,
          "Something went wrong"
        )

        log_content = log_output.string
        expect(log_content).to include('user_session_id: "rstuvwxyz"')
        expect(log_content).to include("An error occurred")
      end
    end
  end
end
