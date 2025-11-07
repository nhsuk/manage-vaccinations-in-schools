# frozen_string_literal: true

describe "Session timeout endpoints" do
  scenario "Authenticated user can check session time remaining" do
    given_i_am_signed_in
    when_i_call_the_time_remaining_endpoint
    then_i_get_a_json_response_with_time_remaining
  end

  scenario "Unauthenticated user gets 401 unauthorized from time remaining endpoint" do
    when_i_call_the_time_remaining_endpoint
    then_i_get_401_unauthorized
  end

  scenario "Calling the time remaining endpoint does not update last activity" do
    given_i_am_signed_in
    when_i_call_the_time_remaining_endpoint
    then_i_get_a_json_response_with_time_remaining
    and_i_store_the_time_remaining

    when_i_call_the_time_remaining_endpoint
    then_i_get_a_json_response_with_time_remaining
    and_the_time_remaining_is_the_same_or_less
  end

  scenario "Calling the refresh session endpoint updates last activity" do
    given_i_am_signed_in
    when_i_call_the_time_remaining_endpoint
    then_i_get_a_json_response_with_time_remaining
    and_i_store_the_time_remaining

    sleep(1)

    when_i_call_the_refresh_session_endpoint
    then_i_get_a_json_response_with_time_remaining
    and_the_time_remaining_is_reset
  end

  scenario "Unauthenticated user gets 401 unauthorized from refresh session endpoint" do
    when_i_call_the_refresh_session_endpoint
    then_i_get_401_unauthorized
  end

  private

  def given_i_am_signed_in
    @user = create(:user)
    sign_in @user
  end

  def when_i_call_the_time_remaining_endpoint
    visit "/users/sessions/time-remaining"
  end

  def then_i_get_a_json_response_with_time_remaining
    expect(page.response_headers["Content-Type"]).to include("application/json")

    response_body = JSON.parse(page.body)
    expect(response_body).to have_key("time_remaining_seconds")
    expect(response_body["time_remaining_seconds"]).to be_a(Integer)
    expect(response_body["time_remaining_seconds"]).to be > 0
  end

  def then_i_get_401_unauthorized
    expect(page.status_code).to eq(401)
    expect(page.response_headers["Content-Type"]).to include("application/json")

    response_body = JSON.parse(page.body)
    expect(response_body).to have_key("error")
    expect(response_body["error"]).to eq("Unauthorized")
  end

  def and_i_store_the_time_remaining
    @first_time_remaining = JSON.parse(page.body)["time_remaining_seconds"]
  end

  def and_the_time_remaining_is_the_same_or_less
    second_time_remaining = JSON.parse(page.body)["time_remaining_seconds"]
    expect(second_time_remaining).to be <= @first_time_remaining
  end

  def when_i_call_the_refresh_session_endpoint
    page.driver.post "/users/sessions/refresh"
  end

  def and_the_time_remaining_is_reset
    new_time_remaining = JSON.parse(page.body)["time_remaining_seconds"]

    # The new time remaining should be close to the full timeout duration.
    expect(new_time_remaining).to be >= @first_time_remaining - 1
    expect(new_time_remaining).to be > (Devise.timeout_in.to_i - 10)
  end
end
