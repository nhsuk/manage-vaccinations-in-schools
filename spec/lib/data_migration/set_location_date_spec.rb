# frozen_string_literal: true

describe DataMigration::SetLocationDate do
  subject(:call) { described_class.call }

  let(:location) { create(:school) }
  let(:session) { create(:session, location:) }
  let(:session_date) { session.session_dates.first }

  context "with a Gillick assessment" do
    let(:gillick_assessment) do
      create(
        :gillick_assessment,
        :competent,
        session_date:,
        location_id: nil,
        date: nil
      )
    end

    it "sets the location" do
      expect { call }.to change { gillick_assessment.reload.location }.from(
        nil
      ).to(location)
    end

    it "sets the date" do
      expect { call }.to change { gillick_assessment.reload.date }.from(nil).to(
        session_date.value
      )
    end
  end

  context "with a pre-screening" do
    let(:pre_screening) do
      create(:pre_screening, session_date:, location_id: nil, date: nil)
    end

    it "sets the location" do
      expect { call }.to change { pre_screening.reload.location }.from(nil).to(
        location
      )
    end

    it "sets the date" do
      expect { call }.to change { pre_screening.reload.date }.from(nil).to(
        session_date.value
      )
    end
  end
end
