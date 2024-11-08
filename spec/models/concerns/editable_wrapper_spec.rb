# frozen_string_literal: true

describe EditableWrapper do
  let(:model_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include EditableWrapper

      attribute :value, :string

      def save!(context:)
      end

      def reset!
      end
    end
  end

  let(:instance) { OpenStruct.new(id: 1, value: "abc", persisted?: true) }

  let(:model) { model_class.new }

  describe "#editing?" do
    subject(:editing?) { model.editing? }

    it { should be(false) }

    context "when loading from an instance" do
      before { model.read_from!(instance) }

      it { should be(true) }
    end
  end

  describe "#read_from!" do
    subject(:read_from!) { model.read_from!(instance) }

    it "saves the ID of the instance" do
      expect { read_from! }.to change(model, :editing_id).from(nil).to(1)
    end

    it "saves the attributes from the instances" do
      expect { read_from! }.to change(model, :value).from(nil).to("abc")
    end
  end

  describe "#write_to!" do
    subject(:write_to!) { model.write_to!(instance) }

    context "when editing the instance" do
      before do
        model.read_from!(instance)
        model.value = "def"
      end

      it "updates the instance" do
        expect { write_to! }.to change(instance, :value).to("def")
      end
    end

    context "when editing a different instance" do
      before do
        model.read_from!(OpenStruct.new(id: 2, value: "abc"))
        model.value = "def"
      end

      it "raises an error" do
        expect { write_to! }.to raise_error(
          EditableWrapper::CannotWriteDifferentRecord
        )
      end
    end

    context "when not editing and the instance is new" do
      let(:instance) { OpenStruct.new(id: nil, value: nil, persisted?: false) }

      before { model.value = "abc" }

      it "updates the instance" do
        expect { write_to! }.to change(instance, :value).to("abc")
      end
    end

    context "when not editing and instance is persisted" do
      it "raises an error" do
        expect { write_to! }.to raise_error(
          EditableWrapper::CannotWritePersistedRecord
        )
      end
    end
  end
end
