# frozen_string_literal: true

describe "Scheduled consent requests" do
  around { |example| travel_to(Time.zone.local(2024, 2, 18)) { example.run } }

  scenario "Consent requests are sent automatically 3 weeks before session, by default" do
    given_my_team_is_running_an_hpv_vaccination_programme
    and_one_unscheduled_session_exists_with_two_children_and_two_parents_each
    and_i_am_signed_in

    when_i_go_to_my_team_page
    then_i_see_consent_requests_are_sent_3_weeks_before

    when_i_schedule_a_session_4_weeks_away
    and_6_days_pass
    then_no_consent_requests_have_been_sent

    when_1_more_day_passes
    then_all_four_parents_received_consent_requests
  end

  def given_my_team_is_running_an_hpv_vaccination_programme
    programmes = [create(:programme, :hpv)]
    @team = create(:team, :with_one_nurse, :with_generic_clinic, programmes:)
    @location = create(:school, :secondary, team: @team)
    @session =
      create(
        :session,
        :unscheduled,
        location: @location,
        team: @team,
        programmes:
      )
    @user = @team.users.first
  end

  def and_one_unscheduled_session_exists_with_two_children_and_two_parents_each
    2.times do |i|
      parents = [
        create(
          :parent,
          email: "parent1.child#{i + 1}@example.com",
          phone: "0770090000#{2 * i}",
          phone_receive_updates: true
        ),
        create(
          :parent,
          email: "parent2.child#{i + 1}@example.com",
          phone: "0770090000#{2 * i + 1}",
          phone_receive_updates: true
        )
      ]
      create(
        :patient,
        year_group: 8,
        session: @session,
        given_name: "Child#{i + 1}",
        family_name: "Test",
        parents:
      )
    end
  end

  def and_i_am_signed_in
    sign_in @user
  end

  def when_i_go_to_my_team_page
    visit "/"
    click_link "Your team", match: :first
  end

  def then_i_see_consent_requests_are_sent_3_weeks_before
    expect(page).to have_content(
      ["Consent requests", "Send 3 weeks before first session"].join
    )
  end

  def when_i_schedule_a_session_4_weeks_away
    click_link "Sessions"
    choose "Unscheduled"
    click_button "Update results"
    click_link @location.name
    click_link "Schedule sessions"
    click_link "Add session dates"

    session_date = 4.weeks.from_now

    fill_in "Day", with: session_date.day
    fill_in "Month", with: session_date.month
    fill_in "Year", with: session_date.year

    click_button "Continue"
    click_button "Save changes"
  end

  def and_6_days_pass
    travel 6.days
  end

  def when_1_more_day_passes
    travel 1.day
  end

  def then_no_consent_requests_have_been_sent
    EnqueueSchoolConsentRequestsJob.perform_now
    perform_enqueued_jobs
    Sidekiq::Job.drain_all

    expect(email_deliveries).to be_empty
    expect(sms_deliveries).to be_empty
  end

  def then_all_four_parents_received_consent_requests
    EnqueueSchoolConsentRequestsJob.perform_now
    perform_enqueued_jobs
    Sidekiq::Job.drain_all

    expect_email_to(
      "parent1.child1@example.com",
      :consent_school_request_hpv,
      :any
    )
    expect_email_to(
      "parent2.child1@example.com",
      :consent_school_request_hpv,
      :any
    )
    expect_email_to(
      "parent1.child2@example.com",
      :consent_school_request_hpv,
      :any
    )
    expect_email_to(
      "parent2.child2@example.com",
      :consent_school_request_hpv,
      :any
    )

    expect_sms_to("07700 900000", :consent_school_request, :any)
    expect_sms_to("07700 900001", :consent_school_request, :any)
    expect_sms_to("07700 900002", :consent_school_request, :any)
    expect_sms_to("07700 900003", :consent_school_request, :any)
  end
end
