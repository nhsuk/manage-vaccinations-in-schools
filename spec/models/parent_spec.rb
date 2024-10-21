# frozen_string_literal: true

# == Schema Information
#
# Table name: parents
#
#  id                           :bigint           not null, primary key
#  contact_method_other_details :text
#  contact_method_type          :string
#  email                        :string
#  full_name                    :string
#  phone                        :string
#  phone_receive_updates        :boolean          default(FALSE), not null
#  recorded_at                  :datetime
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#
# Indexes
#
#  index_parents_on_email  (email)
#

describe Parent do
  describe "validations" do
    it { should_not validate_presence_of(:email) }
    it { should_not validate_presence_of(:full_name) }
    it { should_not validate_presence_of(:phone) }

    context "when users wants to receive text updates" do
      subject(:parent) { build(:parent, phone_receive_updates: true) }

      it { should validate_presence_of(:phone) }
    end
  end

  it { should normalize(:email).from("  joHn@doe.com ").to("john@doe.com") }
  it { should normalize(:email).from("").to(nil) }

  it { should normalize(:phone).from(" 01234 567890 ").to("01234567890") }
  it { should normalize(:phone).from("").to(nil) }

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

  describe "#reset_unused_fields" do
    it "resets contact method fields when phone number is removed" do
      subject =
        build(:parent, :contact_method_other, phone_receive_updates: false)
      subject.update!(phone: nil)
      expect(subject.contact_method_type).to be_nil
      expect(subject.contact_method_other_details).to be_nil
    end
  end
end
