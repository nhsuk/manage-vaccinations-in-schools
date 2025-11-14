# frozen_string_literal: true

describe UserSessionLoggingConcern do
  # rubocop:disable RSpec/DescribedClass
  controller(ActionController::Base) do
    include UserSessionLoggingConcern

    def index
      head :ok
    end
  end
  # rubocop:enable RSpec/DescribedClass

  describe "#add_a_user_session_id_log_tag", order: :defined do
    user_session_id = nil

    it "adds a user_session_id tag to the log" do
      user_session_id = capture_log_tags { get :index }.first[:user_session_id]

      expect(user_session_id).not_to be_nil
    end

    it "changes the session ID in a new session" do
      new_user_session_id =
        capture_log_tags { get :index }.first[:user_session_id]

      expect(new_user_session_id).not_to eq(user_session_id)
    end

    it "maintains the same id throughout a single session" do
      user_session_ids =
        capture_log_tags { 2.times { get :index } }.pluck(:user_session_id)

      expect(user_session_ids.size).to eq(2)
      expect(user_session_ids.uniq.size).to eq(1)
    end
  end
end
