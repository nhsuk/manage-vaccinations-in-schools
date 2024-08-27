# frozen_string_literal: true

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
#  recorded_at          :datetime
#  relationship         :integer
#  relationship_other   :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

describe Parent do
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
      expect(subject.phone).to be_nil
    end

    it "sets the phone number to nil if it's blank" do
      subject = build(:parent, phone: " ")
      expect(subject.phone).to be_nil
    end
  end

  describe "#email=" do
    it "strips whitespace and downcases the email" do
      subject = build(:parent, email: "  joHn@doe.com ")
      expect(subject.email).to eq("john@doe.com")
    end

    it "leaves nil as nil" do
      subject = build(:parent, email: nil)
      expect(subject.email).to be_nil
    end
  end

  describe "#reset_unused_fields" do
    it "resets contact method fields when phone number is removed" do
      subject =
        build(:parent, contact_method: :other, contact_method_other: "foo")
      subject.update!(phone: nil)
      expect(subject.contact_method).to be_nil
      expect(subject.contact_method_other).to be_nil
    end

    it "resets relationship_other if relationship is updated" do
      subject =
        build(
          :parent,
          relationship: "other",
          relationship_other: "granddad",
          parental_responsibility: "yes"
        )
      subject.update!(relationship: "mother")
      expect(subject.relationship_other).to be_nil
    end
  end
end
