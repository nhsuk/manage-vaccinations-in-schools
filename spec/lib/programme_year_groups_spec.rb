# frozen_string_literal: true

describe ProgrammeYearGroups do
  shared_examples "all examples" do
    subject(:year_groups) { programme_year_groups[programme] }

    let(:programme) { create(:programme, :hpv) }

    context "for a programme not administered" do
      let(:team) { create(:team) }

      it { should be_empty }
    end

    context "for a programme administered but no schools" do
      let(:team) { create(:team, programmes: [programme]) }

      it { should be_empty }
    end

    context "for a programme administered with schools" do
      let(:team) { create(:team, programmes: [programme]) }

      before { create(:school, team:) }

      it { should eq([8, 9, 10, 11]) }
    end

    context "when the school administers the programme for an extra year" do
      let(:team) { create(:team, programmes: [programme]) }

      before do
        location = create(:school, team:)
        create(
          :location_programme_year_group,
          location:,
          programme:,
          year_group: 12
        )
      end

      it { should eq([8, 9, 10, 11, 12]) }
    end

    context "for a different programme" do
      let(:team) { create(:team, programmes: [create(:programme, :flu)]) }

      before { create(:school, :primary, team:) }

      it { should be_empty }
    end
  end

  describe "#[]" do
    context "with a scope" do
      let(:programme_year_groups) do
        described_class.new(team.location_programme_year_groups)
      end

      include_examples "all examples"
    end

    context "with a loaded scope" do
      let(:programme_year_groups) do
        described_class.new(
          Team
            .includes(:location_programme_year_groups)
            .find(team.id)
            .location_programme_year_groups
        )
      end

      include_examples "all examples"
    end

    context "with an array" do
      let(:programme_year_groups) do
        described_class.new(team.location_programme_year_groups.to_a)
      end

      include_examples "all examples"
    end
  end
end
