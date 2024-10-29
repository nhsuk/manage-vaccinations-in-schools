# frozen_string_literal: true

describe PendingChangesConcern do
  let(:model_class) do
    Class.new(ApplicationRecord) do
      include PendingChangesConcern

      self.table_name = "patients"

      encrypts :given_name, :family_name, deterministic: true, ignore_case: true
    end
  end

  let(:model) do
    model_class.create!(
      address_postcode: "",
      cohort_id: create(:cohort).id,
      date_of_birth: Time.zone.now,
      given_name: "John",
      decrypted_given_name: "John",
      family_name: "Doe",
      decrypted_family_name: "Doe"
    )
  end

  describe "#stage_changes" do
    it "stages new changes in pending_changes" do
      model.stage_changes(given_name: "Jane", address_line_1: "123 New St")

      expect(model.pending_changes).to eq(
        { "given_name" => "Jane", "address_line_1" => "123 New St" }
      )
    end

    it "does not stage unchanged attributes" do
      model.stage_changes(given_name: "John", family_name: "Smith")

      expect(model.pending_changes).to eq({ "family_name" => "Smith" })
    end

    it "does not stage blank values" do
      model.stage_changes(
        given_name: "",
        family_name: nil,
        address_line_1: "123 New St"
      )

      expect(model.pending_changes).to eq({ "address_line_1" => "123 New St" })
    end

    it "updates the pending_changes attribute" do
      expect { model.stage_changes(given_name: "Jane") }.to change {
        model.reload.pending_changes
      }.from({}).to({ "given_name" => "Jane" })
    end

    it "does not update other attributes directly" do
      model.stage_changes(given_name: "Jane", family_name: "Smith")

      expect(model.given_name).to eq("John")
      expect(model.family_name).to eq("Doe")
    end

    it "does not save any changes if no valid changes are provided" do
      expect { model.stage_changes(given_name: "John") }.not_to(
        change { model.reload.pending_changes }
      )
    end
  end

  describe "#with_pending_changes" do
    it "returns model with pending changes applied, does not modify original" do
      model.stage_changes(given_name: "Jane")
      expect(model.given_name).to eq("John")

      changed_model = model.with_pending_changes
      expect(changed_model.given_name).to eq("Jane")
      expect(changed_model.family_name).to eq("Doe")

      expect(model.given_name).to eq("John")
    end
  end
end
