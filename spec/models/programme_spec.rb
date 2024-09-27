# frozen_string_literal: true

# == Schema Information
#
# Table name: programmes
#
#  id         :bigint           not null, primary key
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_programmes_on_type  (type) UNIQUE
#

describe Programme do
  subject(:programme) { build(:programme) }

  describe "validations" do
    it { should validate_presence_of(:type) }
    it { should validate_inclusion_of(:type).in_array(%w[flu hpv]) }

    context "when vaccines don't match type" do
      subject(:programme) do
        build(:programme, type: "flu", vaccines: [build(:vaccine, type: "hpv")])
      end

      it "is invalid" do
        expect(programme).to be_invalid
        expect(programme.errors[:vaccines]).to include(
          /must be suitable for the programme type/
        )
      end
    end
  end

  describe "#name" do
    subject(:name) { programme.name }

    context "with a Flu programme" do
      let(:programme) { build(:programme, :flu) }

      it { should eq("Flu") }
    end

    context "with an HPV programme" do
      let(:programme) { build(:programme, :hpv) }

      it { should eq("HPV") }
    end
  end

  describe "#year_groups" do
    subject(:year_groups) { programme.year_groups }

    context "with a Flu programme" do
      let(:programme) { build(:programme, :flu) }

      it { should eq([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]) }
    end

    context "with an HPV programme" do
      let(:programme) { build(:programme, :hpv) }

      it { should eq([8, 9, 10, 11]) }
    end
  end
end
