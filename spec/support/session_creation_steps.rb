module SessionCreationSteps
  def start_new_session(school_name:, session_date:, time_of_day:)
    find("a", text: "School sessions", match: :first).click
    click_on "Add a new session"

    expect(page).to have_content("Which school is it at?")
    choose school_name
    click_on "Continue"

    expect(page).to have_content("When is the session?")
    fill_in "Day", with: session_date.day
    fill_in "Month", with: session_date.month
    fill_in "Year", with: session_date.year
    choose time_of_day
    click_on "Continue"
  end

  def select_cohort(names:)
    expect(page).to have_content("Choose cohort for this session")
    all("input[type=checkbox]").each do |checkbox| # uncheck all the children
      checkbox.set(false)
    end

    names.each do |name|
      within page.find("tr", text: name) do
        find("input[type=checkbox]").check
      end
    end

    click_on "Continue"
  end

  def schedule_key_dates(send_consent_on_date:)
    expect(page).to have_content("What’s the timeline for consent requests?")
    within("fieldset", text: "Consent requests") do
      fill_in "Day", with: send_consent_on_date.day
      fill_in "Month", with: send_consent_on_date.month
      fill_in "Year", with: send_consent_on_date.year
    end

    within("fieldset", text: "Reminders") do
      choose "2 days after the first consent request"
    end

    within("fieldset", text: "Deadline for responses") do
      choose "Allow responses until the day of the session"
    end

    click_on "Continue"
  end

  def confirm_session_details(
    number_of_children:,
    send_consent_on_date:,
    session_date:
  )
    expect(page).to have_content("Check and confirm details")
    expect(page).to have_content("Pilot School")
    expect(page).to have_content("Morning")
    expect(page).to have_content("#{number_of_children} child") # could be singular or plural

    expect(page).to have_content(
      "Consent requestsSend on #{send_consent_on_date.strftime("%A, %-d %B %Y")}"
    )
    expect(page).to have_content(
      "RemindersSend on #{(send_consent_on_date + 2.days).strftime("%A, %-d %B %Y")}"
    ) # default
    expect(page).to have_content(
      "Deadline for responsesAllow responses until the day of the session"
    )
    expect(page).to have_content(
      "Date#{session_date.strftime("%A, %-d %B %Y")}"
    )

    click_on "Confirm"
  end
end
