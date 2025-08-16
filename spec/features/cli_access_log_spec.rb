# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis access-log" do
  before { given_access_log_entries_exists }

  context "when no arguments are provided" do
    it "runs successfully" do
      when_i_run_the_command
      then_i_see_the_log_entries
    end
  end

  context "when the patient ID is provided" do
    it "runs successfully" do
      when_i_run_the_command_with_patient
      then_i_see_the_log_entries
    end
  end

  context "when the user email address is provided" do
    it "runs successfully" do
      when_i_run_the_command_with_user
      then_i_see_the_log_entries
    end
  end

  private

  def command
    Dry::CLI.new(MavisCLI).call(arguments: %w[access-log])
  end

  def command_with_patient
    Dry::CLI.new(MavisCLI).call(arguments: %w[access-log -p 1000])
  end

  def command_with_user
    Dry::CLI.new(MavisCLI).call(arguments: %w[access-log -u nurse@example.com])
  end

  def given_access_log_entries_exists
    @patient = create(:patient, id: 1000)
    @user = create(:nurse, email: "nurse@example.com")

    create_list(:access_log_entry, 4, patient: @patient, user: @user)
  end

  def when_i_run_the_command
    @output = capture_output { command }
  end

  def when_i_run_the_command_with_patient
    @output = capture_output { command }
  end

  def when_i_run_the_command_with_user
    @output = capture_output { command }
  end

  def then_i_see_the_log_entries
    expect(@output.lines.count).to eq(4)
    expect(@output).to include(@patient.full_name)
    expect(@output).to include(@user.full_name)
  end
end
