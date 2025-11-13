# frozen_string_literal: true

describe DataMigration::SetSessionDates do
  subject(:call) { described_class.call }

  let(:location) { create(:school) }
  let(:session) do
    create(:session, dates: [Date.new(2020, 1, 1), Date.new(2020, 1, 2)])
  end

  it "sets the dates" do
    expect { call }.to change { session.reload.attributes["dates"] }.from(
      nil
    ).to([Date.new(2020, 1, 1), Date.new(2020, 1, 2)])
  end
end
