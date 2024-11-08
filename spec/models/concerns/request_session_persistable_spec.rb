# frozen_string_literal: true

describe RequestSessionPersistable do
  let(:model_class) do
    Class.new do
      include RequestSessionPersistable

      def self.request_session_key
        "key"
      end

      attribute :value, :string

      validates :value, presence: true, on: :update

      def reset_unused_fields
      end
    end
  end

  let(:model) { model_class.new(request_session:, current_user:, **attributes) }

  let(:request_session) { {} }
  let(:current_user) { nil }

  describe "#save" do
    subject(:save) { model.save(context: :update) }

    context "when invalid" do
      let(:attributes) { {} }

      it { should be(false) }
    end

    context "when valid" do
      let(:attributes) { { value: "abc" } }

      it { should be(true) }

      it "saves the attributes in the session" do
        expect { save }.to change { request_session }.to(
          { "key" => { "value" => "abc" } }
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
      let(:attributes) { { value: "abc" } }

      it "doesn't raise an error" do
        expect { save! }.not_to raise_error
      end

      it "saves the attributes in the session" do
        expect { save! }.to change { request_session }.to(
          { "key" => { "value" => "abc" } }
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
      let(:update_attributes) { { value: "abc" } }

      it { should be(true) }

      it "saves the attributes in the session" do
        expect { update }.to change { request_session }.to(
          { "key" => { "value" => "abc" } }
        )
      end
    end
  end

  describe "#reset!" do
    subject(:reset!) { model.reset! }

    let(:attributes) { { value: "abc" } }

    it "resets all the attributes and saves to the session" do
      expect { reset! }.to change(model, :attributes).to(
        { "value" => nil }
      ).and change { request_session }.to({ "key" => { "value" => nil } })
    end
  end
end
