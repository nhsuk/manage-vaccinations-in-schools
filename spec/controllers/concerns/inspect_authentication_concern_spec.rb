# frozen_string_literal: true

describe InspectAuthenticationConcern do
  let(:sample_class) do
    c =
      Class.new do
        include InspectAuthenticationConcern

        public :ensure_ops_tools_feature_enabled
      end

    c.new
  end

  describe "#ensure_ops_tools_feature_enabled" do
    context "when ops_tools feature flag is enabled" do
      before { Flipper.enable(:ops_tools) }
      after { Flipper.disable(:ops_tools) }

      it "does not raise an error" do
        expect {
          sample_class.ensure_ops_tools_feature_enabled
        }.not_to raise_error
      end
    end

    context "when ops_tools feature flag is disabled" do
      before { Flipper.disable(:ops_tools) }

      it "raises ActionController::RoutingError with 'Not Found' message" do
        expect { sample_class.ensure_ops_tools_feature_enabled }.to raise_error(
          ActionController::RoutingError,
          "Not Found"
        )
      end
    end
  end
end
