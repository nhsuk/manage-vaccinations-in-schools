# == Schema Information
#
# Table name: parents
#
#  id                   :bigint           not null, primary key
#  contact_method       :integer
#  contact_method_other :text
#  email                :string
#  name                 :string
#  phone                :string
#  relationship         :integer
#  relationship_other   :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
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

  describe "#phone=" do
    it "strips non-numeric characters" do
      subject = build(:parent, phone: "01234 567890")
      expect(subject.phone).to eq("01234567890")
    end

    it "leaves nil as nil" do
      subject = build(:parent, phone: nil)
      expect(subject.phone).to eq(nil)
    end

    it "sets the phone number to nil if it's blank" do
      subject = build(:parent, phone: " ")
      expect(subject.phone).to eq(nil)
    end
  end

  describe "#email=" do
    it "strips whitespace and downcases the email" do
      subject = build(:parent, email: "  joHn@doe.com ")
      expect(subject.email).to eq("john@doe.com")
    end

    it "leaves nil as nil" do
      subject = build(:parent, email: nil)
      expect(subject.email).to eq(nil)
    end
  end
end
