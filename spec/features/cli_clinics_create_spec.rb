# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis clinics create" do
  context "with valid arguments" do
    it "runs successfully" do
      when_i_run_the_command
      then_the_clinic_is_created
    end
  end

  private

  def command
    Dry::CLI.new(MavisCLI).call(
      arguments: %w[clinics create 123456 Clinic Line Town SW1A1AA]
    )
  end

  def when_i_run_the_command
    @output = capture_output { command }
  end

  def then_the_clinic_is_created
    clinic = Location.community_clinic.find_by!(ods_code: "123456")

    expect(clinic.name).to eq("Clinic")
    expect(clinic.address_line_1).to eq("Line")
    expect(clinic.address_town).to eq("Town")
    expect(clinic.address_postcode).to eq("SW1A 1AA")
  end
end
