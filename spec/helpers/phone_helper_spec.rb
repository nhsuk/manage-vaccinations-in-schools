# frozen_string_literal: true

describe PhoneHelper do
  describe "#format_phone_with_instructions" do
    subject(:formatted_phone) { helper.format_phone_with_instructions(entity) }

    context "when phone instructions are present" do
      let(:entity) do
        create(
          :team,
          name: "Team",
          email: "team@example.com",
          phone: "01234 567890",
          phone_instructions: "option 1"
        )
      end

      it { should eq("01234 567890 (option 1)") }
    end

    context "when phone instructions are blank" do
      let(:entity) do
        create(
          :team,
          name: "Team",
          email: "team@example.com",
          phone: "01234 567890",
          phone_instructions: nil
        )
      end

      it { should eq("01234 567890") }
    end

    context "when phone instructions are an empty string" do
      let(:entity) do
        create(
          :team,
          name: "Team",
          email: "team@example.com",
          phone: "01234 567890",
          phone_instructions: ""
        )
      end

      it { should eq("01234 567890") }
    end
  end
end
