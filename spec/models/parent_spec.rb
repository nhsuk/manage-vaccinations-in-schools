# frozen_string_literal: true

# == Schema Information
#
# Table name: parents
#
#  id                           :bigint           not null, primary key
#  contact_method_other_details :text
#  contact_method_type          :string
#  email                        :string
#  name                         :string
#  phone                        :string
#  recorded_at                  :datetime
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#

describe Parent do
  describe "#contact_method_description" do
    subject(:contact_method_description) { parent.contact_method_description }

    context "when the parent/carer can only receive texts" do
      let(:parent) { build(:parent, :contact_method_text) }

      it { should eq("Can only receive text messages") }
    end

    context "when the parent/carer can only receive calls" do
      let(:parent) { build(:parent, :contact_method_voice) }

      it { should eq("Can only receive voice calls") }
    end

    context "when the parent/carer has no preference either way" do
      let(:parent) { build(:parent, :contact_method_any) }

      it { should eq("No specific needs") }
    end

    context "when the parent/carer has other preferences" do
      let(:parent) do
        build(
          :parent,
          :contact_method_other,
          contact_method_other_details:
            "Please call 01234 567890 ext 8910 between 9am and 5pm."
        )
      end

      it do
        expect(contact_method_description).to eq(
          "Other – Please call 01234 567890 ext 8910 between 9am and 5pm."
        )
      end
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
      subject = build(:parent, :contact_method_other)
      subject.update!(phone: nil)
      expect(subject.contact_method_type).to be_nil
      expect(subject.contact_method_other_details).to be_nil
    end
  end
end
