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

  describe "#common_delivery_sites" do
    subject(:common_delivery_sites) { programme.common_delivery_sites }

    context "with a Flu programme" do
      let(:programme) { build(:programme, :flu) }

      it "raises an error" do
        expect { common_delivery_sites }.to raise_error(NotImplementedError)
      end
    end

    context "with an HPV programme" do
      let(:programme) { build(:programme, :hpv) }

      it { should eq(%w[left_arm_upper_position right_arm_upper_position]) }
    end

    context "with an MenACWY programme" do
      let(:programme) { build(:programme, :menacwy) }

      it { should eq(%w[left_arm_upper_position right_arm_upper_position]) }
    end

    context "with an Td/IPV programme" do
      let(:programme) { build(:programme, :td_ipv) }

      it { should eq(%w[left_arm_upper_position right_arm_upper_position]) }
    end
  end

  describe "#vaccinated_dose_sequence" do
    subject(:vaccinated_dose_sequence) { programme.vaccinated_dose_sequence }

    context "with a Flu programme" do
      let(:programme) { build(:programme, :flu) }

      it { should eq(1) }
    end

    context "with an HPV programme" do
      let(:programme) { build(:programme, :hpv) }

      it { should eq(1) }
    end

    context "with a MenACWY programme" do
      let(:programme) { build(:programme, :menacwy) }

      it { should eq(1) }
    end

    context "with an Td/IPV programme" do
      let(:programme) { build(:programme, :td_ipv) }

      it { should eq(5) }
    end
  end

  describe "#default_dose_sequence" do
    subject(:default_dose_sequence) { programme.default_dose_sequence }

    context "with a Flu programme" do
      let(:programme) { build(:programme, :flu) }

      it { should be_nil }
    end

    context "with an HPV programme" do
      let(:programme) { build(:programme, :hpv) }

      it { should eq(1) }
    end

    context "with a MenACWY programme" do
      let(:programme) { build(:programme, :menacwy) }

      it { should be_nil }
    end

    context "with an Td/IPV programme" do
      let(:programme) { build(:programme, :td_ipv) }

      it { should be_nil }
    end
  end

  describe "#maximum_dose_sequence" do
    subject(:maximum_dose_sequence) { programme.maximum_dose_sequence }

    context "with a Flu programme" do
      let(:programme) { build(:programme, :flu) }

      it { should eq(1) }
    end

    context "with an HPV programme" do
      let(:programme) { build(:programme, :hpv) }

      it { should eq(3) }
    end

    context "with a MenACWY programme" do
      let(:programme) { build(:programme, :menacwy) }

      it { should eq(3) }
    end

    context "with an Td/IPV programme" do
      let(:programme) { build(:programme, :td_ipv) }

      it { should eq(5) }
    end
  end
end
