# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis nhs-api access-token" do
  before { NHS::API.instance_variable_set(:@auth_info, nil) }

  it "runs successfully" do
    given_the_request_is_stubbed

    when_i_run_the_command
    then_an_access_token_is_output
  end

  def command
    Dry::CLI.new(MavisCLI).call(arguments: %w[nhs-api access-token])
  end

  def given_the_request_is_stubbed
    stub_request(
      :post,
      "https://sandbox.api.service.nhs.uk/oauth2/token"
    ).to_return_json(
      body: {
        issued_at: Time.zone.now.strftime("%Q"),
        expires_in: 599,
        access_token: "new-token"
      }
    )
  end

  def when_i_run_the_command
    @output = capture_output { command }
  end

  def then_an_access_token_is_output
    expect(@output).to include("new-token")
  end
end
