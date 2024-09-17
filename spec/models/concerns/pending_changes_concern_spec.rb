# frozen_string_literal: true

describe PendingChangesConcern do
  let(:model_class) do
    Class.new(ApplicationRecord) do
      include PendingChangesConcern

      self.table_name = "patients"
    end
  end

  let(:model) do
    model_class.create(
      first_name: "John",
      last_name: "Doe",
      date_of_birth: Time.zone.now,
      address_postcode: ""
    )
  end

  describe "#stage_changes" do
    it "stages new changes in pending_changes" do
      model.stage_changes(first_name: "Jane", address_line_1: "123 New St")

      expect(model.pending_changes).to eq(
        { "first_name" => "Jane", "address_line_1" => "123 New St" }
      )
    end

    it "does not stage unchanged attributes" do
      model.stage_changes(first_name: "John", last_name: "Smith")

      expect(model.pending_changes).to eq({ "last_name" => "Smith" })
    end

    it "does not stage blank values" do
      model.stage_changes(
        first_name: "",
        last_name: nil,
        address_line_1: "123 New St"
      )

      expect(model.pending_changes).to eq({ "address_line_1" => "123 New St" })
    end

    it "updates the pending_changes attribute" do
      expect { model.stage_changes(first_name: "Jane") }.to change {
        model.reload.pending_changes
      }.from({}).to({ "first_name" => "Jane" })
    end

    it "does not update other attributes directly" do
      model.stage_changes(first_name: "Jane", last_name: "Smith")

      expect(model.first_name).to eq("John")
      expect(model.last_name).to eq("Doe")
    end

    it "does not save any changes if no valid changes are provided" do
      expect { model.stage_changes(first_name: "John") }.not_to(
        change { model.reload.pending_changes }
      )
    end
  end

  describe "#with_pending_changes" do
    it "returns the model with pending changes applied" do
      model.stage_changes(first_name: "Jane")
      expect(model.first_name).to eq("John")

      changed_model = model.with_pending_changes
      expect(changed_model.first_name).to eq("Jane")
      expect(changed_model.last_name).to eq("Doe")
    end
  end
end
