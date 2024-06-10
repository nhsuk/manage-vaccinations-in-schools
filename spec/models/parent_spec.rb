require "rails_helper"

RSpec.describe Parent do
  describe "#phone_contact_method_description" do
    it "describes the phone contact method when parent/carer can only receive texts" do
      parent = build(:parent, contact_method: :text)

      expect(parent.phone_contact_method_description).to eq(
        "Can only receive text messages"
      )
    end

    it "describes the phone contact method when parent/carer can only receive calls" do
      parent = build(:parent, contact_method: :voice)

      expect(parent.phone_contact_method_description).to eq(
        "Can only receive voice calls"
      )
    end

    it "describes the phone contact method when parent/carer has no preference either way" do
      parent = build(:parent, contact_method: :any)

      expect(parent.phone_contact_method_description).to eq("No specific needs")
    end

    it "describes the phone contact method when parent/carer has other preferences" do
      parent =
        build(
          :parent,
          contact_method: :other,
          contact_method_other:
            "Please call 01234 567890 ext 8910 between 9am and 5pm."
        )

      expect(parent.phone_contact_method_description).to eq(
        "Other – Please call 01234 567890 ext 8910 between 9am and 5pm."
      )
    end
  end
end
