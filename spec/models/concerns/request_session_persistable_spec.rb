# frozen_string_literal: true

describe RequestSessionPersistable do
  let(:model_class) do
    Class.new do
      include RequestSessionPersistable

      attribute :string, :string
      attribute :datetime, :datetime

      validates :string, presence: true, on: :update

      def request_session_key = "key"

      def reset_unused_attributes
      end
    end
  end

  let(:model) { model_class.new(request_session:, **attributes) }

  let(:request_session) { {} }

  describe "#initialize" do
    context "with a datetime attribute" do
      let(:attributes) { { datetime: "2025-05-21 11:48:17 +0100" } }

      it "isn't marked as having changed" do
        expect(model.changed?).to be(false)
      end

      it "parses and keeps the time zone" do
        expect(model.datetime).to eq(Time.zone.local(2025, 5, 21, 11, 48, 17))
        expect(model.datetime).to be_a(ActiveSupport::TimeWithZone)
        expect(model.datetime.time_zone.name).to eq("London")
      end

      context "when system timezone is UTC" do
        around { |example| ClimateControl.modify(TZ: "UTC") { example.run } }

        it "parses and keeps the time zone" do
          expect(model.datetime).to eq(Time.zone.local(2025, 5, 21, 11, 48, 17))
          expect(model.datetime).to be_a(ActiveSupport::TimeWithZone)
          expect(model.datetime.time_zone.name).to eq("London")
        end
      end
    end
  end

  describe "#save" do
    subject(:save) { model.save(context: :update) }

    context "when invalid" do
      let(:attributes) { {} }

      it { should be(false) }
    end

    context "when valid" do
      let(:attributes) { { string: "abc" } }

      it { should be(true) }

      it "saves the attributes in the session" do
        expect { save }.to change { request_session }.to(
          { "key" => { "datetime" => nil, "string" => "abc" } }
        )
      end
    end
  end

  describe "#save!" do
    subject(:save!) { model.save!(context: :update) }

    context "when invalid" do
      let(:attributes) { {} }

      it "raises an error" do
        expect { save! }.to raise_error(
          RequestSessionPersistable::RecordInvalid
        )
      end
    end

    context "when valid" do
      let(:attributes) { { string: "abc" } }

      it "doesn't raise an error" do
        expect { save! }.not_to raise_error
      end

      it "saves the attributes in the session" do
        expect { save! }.to change { request_session }.to(
          { "key" => { "datetime" => nil, "string" => "abc" } }
        )
      end
    end
  end

  describe "#update" do
    subject(:update) { model.update(update_attributes) }

    let(:attributes) { {} }

    context "when invalid" do
      let(:update_attributes) { {} }

      it { should be(false) }
    end

    context "when valid" do
      let(:update_attributes) { { string: "abc" } }

      it { should be(true) }

      it "saves the attributes in the session" do
        expect { update }.to change { request_session }.to(
          { "key" => { "datetime" => nil, "string" => "abc" } }
        )
      end
    end
  end

  describe "#reset!" do
    subject(:reset!) { model.reset! }

    let(:attributes) { { string: "abc" } }

    it "resets all the attributes and saves to the session" do
      expect { reset! }.to change(model, :attributes).to(
        { "datetime" => nil, "string" => nil }
      ).and change { request_session }.to(
              { "key" => { "datetime" => nil, "string" => nil } }
            )
    end
  end
end
