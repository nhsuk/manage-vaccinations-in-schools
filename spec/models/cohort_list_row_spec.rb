# frozen_string_literal: true

require "rails_helper"

describe CohortListRow, type: :model do
  describe "school_urn validations" do
    subject(:cohort_list_row) { described_class.new(team:) }

    let(:user) { create(:user, team:) }
    let(:location) { create(:location) }
    let(:location2) { create(:location) }
    let(:team) { create(:team, locations: [location]) }

    it { should_not allow_value(location2.id).for(:school_urn) }
  end
end
