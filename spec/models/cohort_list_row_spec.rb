require "rails_helper"

RSpec.describe CohortListRow, type: :model do
  describe "school_urn validations" do
    let(:user) { create(:user, team:) }
    let(:location) { create(:location) }
    let(:location2) { create(:location) }
    let(:team) { create(:team, locations: [location]) }

    subject(:cohort_list_row) { described_class.new(team:) }

    it { should_not allow_value(location2.id).for(:school_urn) }
  end
end
