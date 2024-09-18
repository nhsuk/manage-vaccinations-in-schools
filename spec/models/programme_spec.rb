# frozen_string_literal: true

# == Schema Information
#
# Table name: programmes
#
#  id            :bigint           not null, primary key
#  academic_year :integer
#  end_date      :date
#  name          :string
#  start_date    :date
#  type          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  team_id       :integer          not null
#
# Indexes
#
#  idx_on_name_type_academic_year_team_id_f5cd28cbec  (name,type,academic_year,team_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#

describe Programme, type: :model do
  subject(:programme) do
    build(
      :programme,
      academic_year: 2024,
      start_date: Date.new(2024, 9, 1),
      end_date: Date.new(2025, 7, 31)
    )
  end

  it { should normalize(:name).from(" abc ").to("abc") }

  describe "validations" do
    it { should validate_presence_of(:name).on(:update) }

    it { should validate_presence_of(:type).on(:update) }
    it { should validate_inclusion_of(:type).in_array(%w[flu hpv]) }

    it { should validate_presence_of(:academic_year).on(:update) }

    it do
      expect(programme).to validate_comparison_of(:academic_year)
        .on(:update)
        .is_greater_than_or_equal_to(2000)
        .is_less_than_or_equal_to(Time.zone.today.year + 5)
    end

    it { should validate_presence_of(:start_date).on(:update) }

    it do
      expect(programme).to validate_comparison_of(:start_date)
        .on(:update)
        .is_greater_than_or_equal_to(Date.new(2024, 1, 1))
        .is_less_than(Date.new(2025, 7, 31))
    end

    it { should validate_presence_of(:end_date).on(:update) }

    it do
      expect(programme).to validate_comparison_of(:end_date)
        .on(:update)
        .is_greater_than(Date.new(2024, 9, 1))
        .is_less_than_or_equal_to(Date.new(2025, 12, 31))
    end

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
