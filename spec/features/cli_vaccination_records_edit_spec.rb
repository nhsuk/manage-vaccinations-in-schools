# frozen_string_literal: true

describe "mavis vaccination-records edit" do
  it "updates an allowed field" do
    given_a_vaccination_record_exists
    when_i_run_the_edit_command_to_update_uuid
    then_the_uuid_is_updated
  end

  it "rejects a disallowed field" do
    given_a_vaccination_record_exists
    when_i_attempt_to_update_a_disallowed_field
    then_i_see_an_attribute_not_editable_error
    and_the_outcome_is_unchanged
  end

  private

  def given_a_vaccination_record_exists
    team = create(:team)
    programme = CachedProgramme.hpv
    patient = create(:patient, team:)
    @vaccination_record = create(:vaccination_record, patient:, programme:)
  end

  def when_i_run_the_edit_command_to_update_uuid
    @new_uuid = SecureRandom.uuid

    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: [
            "vaccination-records",
            "edit",
            @vaccination_record.id.to_s,
            "uuid=#{@new_uuid}"
          ]
        )
      end
  end

  def when_i_attempt_to_update_a_disallowed_field
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: [
            "vaccination-records",
            "edit",
            @vaccination_record.id.to_s,
            "outcome=refused"
          ]
        )
      end
  end

  def then_the_uuid_is_updated
    expect(@output).to include("Successfully updated VaccinationRecord")
    expect(@vaccination_record.reload.uuid).to eq(@new_uuid)
  end

  def then_i_see_an_attribute_not_editable_error
    expect(@output).to include(
      "Attribute 'outcome' is not editable by this tool"
    )
  end

  def and_the_outcome_is_unchanged
    expect(@vaccination_record.reload.outcome).to eq("administered")
  end
end
