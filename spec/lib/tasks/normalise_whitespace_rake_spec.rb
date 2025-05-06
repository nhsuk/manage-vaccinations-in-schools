# frozen_string_literal: true

describe "normalise_whitespace" do
  subject(:invoke_task) { Rake::Task["normalise_whitespace"].invoke }

  after { Rake.application["normalise_whitespace"].reenable }

  let!(:patient_with_whitespace) do
    create(
      :patient,
      given_name: "  John  \t",
      family_name: "\n Doe  ",
      preferred_given_name: "  Johnny\u200D  ",
      preferred_family_name: "  \u00A0Doe\u00A0  ",
      address_line_1: "  123\t\tMain  St  ",
      address_line_2: "  Apt\n\n2  ",
      address_town: "  Test\u200D Town  ",
      registration: "  REG123\u00A0  "
    )
  end

  let!(:patient_with_clean_data) do
    create(
      :patient,
      given_name: "Alice",
      family_name: "Smith",
      preferred_given_name: "Al",
      preferred_family_name: "Smithy",
      address_line_1: "456 Oak Ave",
      address_line_2: "Unit 5",
      address_town: "Clean City",
      registration: "REG456"
    )
  end

  let!(:patient_with_nil_values) do
    create(
      :patient,
      given_name: "Bob",
      family_name: "Jones",
      preferred_given_name: nil,
      preferred_family_name: nil,
      address_line_1: nil,
      address_line_2: nil,
      address_town: nil,
      registration: nil
    )
  end

  let!(:patient_with_empty_strings) do
    create(
      :patient,
      given_name: "Charlie",
      family_name: "Brown",
      preferred_given_name: "   ",
      preferred_family_name: "",
      address_line_1: "\t\t",
      address_line_2: "\n\n",
      address_town: "  \u200D  ",
      registration: "  \u00A0  "
    )
  end

  let!(:parent_with_whitespace) do
    create(:parent, full_name: "  Parent\u200D  \u00A0Name  ")
  end

  let!(:parent_with_clean_data) { create(:parent, full_name: "Clean Parent") }

  let!(:parent_with_nil_name) { create(:parent, full_name: nil) }

  let!(:parent_with_empty_name) { create(:parent, full_name: "   ") }

  describe "patient field normalization" do
    it "normalizes whitespace in patient fields" do
      invoke_task

      expect(patient_with_whitespace.reload).to have_attributes(
        given_name: "John",
        family_name: "Doe",
        preferred_given_name: "Johnny",
        preferred_family_name: "Doe",
        address_line_1: "123 Main St",
        address_line_2: "Apt 2",
        address_town: "Test Town",
        registration: "REG123"
      )
    end

    it "doesn't change already clean data" do
      expect { invoke_task }.not_to(change(patient_with_clean_data, :reload))
    end

    it "handles nil values correctly" do
      expect { invoke_task }.not_to(change(patient_with_nil_values, :reload))
    end

    it "converts empty/whitespace-only strings to nil" do
      invoke_task

      expect(patient_with_empty_strings.reload).to have_attributes(
        preferred_given_name: nil,
        preferred_family_name: nil,
        address_line_1: nil,
        address_line_2: nil,
        address_town: nil,
        registration: nil
      )
    end
  end

  describe "parent field normalization" do
    it "normalizes whitespace in parent full_name" do
      expect { invoke_task }.to change {
        parent_with_whitespace.reload.full_name
      }.from("  Parent\u200D  \u00A0Name  ").to("Parent Name")
    end

    it "doesn't change already clean data" do
      expect { invoke_task }.not_to(change(parent_with_clean_data, :reload))
    end

    it "handles nil values correctly" do
      expect { invoke_task }.not_to(change(parent_with_nil_name, :reload))
    end

    it "converts empty/whitespace-only strings to nil" do
      expect { invoke_task }.to change {
        parent_with_empty_name.reload.full_name
      }.from("   ").to(nil)
    end
  end

  describe "timestamp preservation" do
    it "doesn't update patient updated_at or created_at timestamps" do
      original_updated_at = patient_with_whitespace.updated_at
      original_created_at = patient_with_whitespace.created_at

      travel_to(1.hour.from_now) { invoke_task }

      patient_with_whitespace.reload
      expect(patient_with_whitespace.updated_at).to eq(original_updated_at)
      expect(patient_with_whitespace.created_at).to eq(original_created_at)
    end

    it "doesn't update parent updated_at or created_at timestamps" do
      original_updated_at = parent_with_whitespace.updated_at
      original_created_at = parent_with_whitespace.created_at

      travel_to(1.hour.from_now) { invoke_task }

      parent_with_whitespace.reload
      expect(parent_with_whitespace.updated_at).to eq(original_updated_at)
      expect(parent_with_whitespace.created_at).to eq(original_created_at)
    end
  end

  describe "error handling" do
    it "doesn't raise errors when processing all patients and parents" do
      expect { invoke_task }.not_to raise_error
    end
  end

  describe "data integrity" do
    it "preserves all other patient attributes" do
      original_attributes =
        patient_with_whitespace.attributes.except(
          "given_name",
          "family_name",
          "preferred_given_name",
          "preferred_family_name",
          "address_line_1",
          "address_line_2",
          "address_town",
          "registration"
        )

      invoke_task

      current_attributes =
        patient_with_whitespace.reload.attributes.except(
          "given_name",
          "family_name",
          "preferred_given_name",
          "preferred_family_name",
          "address_line_1",
          "address_line_2",
          "address_town",
          "registration"
        )

      expect(current_attributes).to eq(original_attributes)
    end

    it "preserves all other parent attributes" do
      original_attributes =
        parent_with_whitespace.attributes.except("full_name")

      invoke_task

      current_attributes =
        parent_with_whitespace.reload.attributes.except("full_name")

      expect(current_attributes).to eq(original_attributes)
    end
  end
end
