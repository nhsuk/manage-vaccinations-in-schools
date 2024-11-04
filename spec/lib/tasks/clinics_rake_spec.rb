# frozen_string_literal: true

describe "clinics:create" do
  def capture_rake_task_output(task_name, *args)
    stdout = StringIO.new
    $stdout = stdout
    Rake::Task[task_name].invoke(*args)
    $stdout = STDOUT
    Rake.application[task_name].reenable
    stdout.string
  end

  before { Rails.application.load_tasks }

  let(:organisation) { create(:organisation, ods_code: "ABC123") }

  it "creates a clinic location with the provided details" do
    team = organisation.generic_team

    expect {
      capture_rake_task_output(
        "clinics:create",
        "Test Clinic",
        "123 Test St",
        "Test Town",
        "TE5 1ST",
        "TEST01",
        "ABC123"
      )
    }.to change { team.locations.count }.by(1)

    location = team.locations.last
    expect(location).to have_attributes(
      type: "community_clinic",
      name: "Test Clinic",
      address_line_1: "123 Test St",
      address_town: "Test Town",
      address_postcode: "TE5 1ST",
      ods_code: "TEST01"
    )
  end
end
