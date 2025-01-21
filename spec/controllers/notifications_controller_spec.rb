# frozen_string_literal: true

describe NotificationsController do
  describe "POST create" do
    let(:notify_log_entry) { create(:notify_log_entry, :email) }

    before { request.headers["Authorization"] = "Bearer #{bearer_token}" }

    context "with an invalid bearer token" do
      let(:bearer_token) { "invalid-bearer-token" }

      it "doesn't update the status" do
        params = { id: notify_log_entry.delivery_id, status: "delivered" }
        post :create, params:, format: :json

        expect(response).to have_http_status(:unauthorized)
        expect(notify_log_entry.reload.delivery_status).to eq("sending")
      end
    end

    shared_examples "handles the status" do |notify_status, model_status|
      context "with a valid bearer token" do
        let(:bearer_token) { "test-bearer-token" } # matches settings/test.yml

        it "handles the #{notify_status} status" do
          params = { id: notify_log_entry.delivery_id, status: notify_status }
          post :create, params:, format: :json

          expect(response).to have_http_status(:no_content)
          expect(notify_log_entry.reload.delivery_status).to eq(model_status)
        end
      end
    end

    include_examples "handles the status", "delivered", "delivered"

    include_examples "handles the status",
                     "permanent-failure",
                     "permanent_failure"

    include_examples "handles the status",
                     "temporary-failure",
                     "temporary_failure"

    include_examples "handles the status",
                     "technical-failure",
                     "technical_failure"
  end
end
