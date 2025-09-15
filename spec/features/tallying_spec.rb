# frozen_string_literal: true

describe "Tallying" do
  scenario "vaccinator can see how many they have administered during a session" do
    given_a_session_for_hpv_and_flu_is_running_today
    and_i_have_administered_two_cervarix_vaccines_for_hpv_programme
    and_administered_one_gardasil_vaccine_for_hpv_programme
    and_administered_one_fluenz_vaccine_for_flu_programme
    and_i_created_vaccination_records_yesterday
    and_vaccinations_are_recorded_by_other_team_members
    and_the_default_vaccine_batches_have_been_set_for_flu_and_hpv

    when_i_visit_the_session_record_tab
    and_i_click_on_the_expander_your_vaccinations_today
    then_i_see_my_vaccination_tallies_for_today_with_default_batches
  end

  scenario "no vaccinations have been administered yet" do
    given_a_session_for_hpv_and_flu_is_running_today
    and_the_default_vaccine_batches_have_been_set_for_flu_and_hpv

    when_i_visit_the_session_record_tab
    and_i_click_on_the_expander_your_vaccinations_today
    then_i_see_my_vaccination_tallies_with_all_zero_values_with_default_batches
  end

  def given_a_session_for_hpv_and_flu_is_running_today
    @flu_programme = create(:programme, :flu, vaccines: [])
    @hpv_programme = create(:programme, :hpv, vaccines: [])

    programmes = [@hpv_programme, @flu_programme]
    team = create(:team, :with_generic_clinic, :with_one_nurse, programmes:)
    @user = team.users.first

    @session =
      create(:session, :today, :requires_no_registration, programmes:, team:)

    @cervarix_vaccine = create(:vaccine, :cervarix, programme: @hpv_programme)
    @cervarix_batch = create(:batch, :not_expired, vaccine: @cervarix_vaccine)

    @gardasil_vaccine = create(:vaccine, :gardasil, programme: @hpv_programme)
    @gardasil_batch = create(:batch, :not_expired, vaccine: @gardasil_vaccine)

    @fluenz_vaccine = create(:vaccine, :fluenz, programme: @flu_programme)
    @fluenz_batch = create(:batch, :not_expired, vaccine: @fluenz_vaccine)

    @patient =
      create(
        :patient_session,
        :consent_given_triage_not_needed,
        :in_attendance,
        session: @session
      ).patient
  end

  def when_i_visit_the_session_record_tab
    sign_in @user, role: :nurse
    visit session_record_path(@session)
  end

  def and_click_on_change_default_batch_link
    within ".nhsuk-table" do
      click_on "Change"
    end
  end

  def and_the_default_vaccine_batches_have_been_set_for_flu_and_hpv
    page.set_rack_session(
      todays_batch: {
        @hpv_programme.type.to_s => {
          @cervarix_vaccine.method => {
            id: @cervarix_batch.id,
            date: Date.current.iso8601
          }
        },
        @flu_programme.type.to_s => {
          @fluenz_vaccine.method => {
            id: @fluenz_batch.id,
            date: Date.current.iso8601
          }
        }
      }
    )
  end

  def and_i_have_administered_two_cervarix_vaccines_for_hpv_programme
    create(
      :vaccination_record,
      batch: @cervarix_batch,
      vaccine: @cervarix_vaccine,
      session: @session,
      programme: @hpv_programme,
      performed_by: @user
    )

    create(
      :vaccination_record,
      batch: @gardasil_batch,
      vaccine: @gardasil_vaccine,
      session: @session,
      programme: @hpv_programme,
      performed_by: @user
    )
  end

  def and_administered_one_gardasil_vaccine_for_hpv_programme
    create(
      :vaccination_record,
      batch: @gardasil_batch,
      vaccine: @gardasil_vaccine,
      session: @session,
      programme: @hpv_programme,
      performed_by: @user
    )
  end

  def and_administered_one_fluenz_vaccine_for_flu_programme
    create(
      :vaccination_record,
      batch: @fluenz_batch,
      vaccine: @fluenz_vaccine,
      session: @session,
      programme: @flu_programme,
      performed_by: @user
    )
  end

  def and_i_created_vaccination_records_yesterday
    create(
      :vaccination_record,
      batch: @cervarix_batch,
      vaccine: @cervarix_vaccine,
      session: @session,
      programme: @hpv_programme,
      performed_by: @user,
      performed_at: Time.zone.yesterday
    )
  end

  def and_vaccinations_are_recorded_by_other_team_members
    create(
      :vaccination_record,
      batch: @cervarix_batch,
      vaccine: @cervarix_vaccine,
      session: @session,
      programme: @hpv_programme
    )
  end

  def then_i_see_my_vaccination_tallies_for_today_with_default_batches
    rows = page.all(".nhsuk-table__row")
    expect(rows[1]).to have_content("Fluenz 1 #{@fluenz_batch.name} Change")
    expect(rows[2]).to have_content("Cervarix 1 #{@cervarix_batch.name} Change")
    expect(rows[3]).to have_content("Gardasil 2 Not set")
  end

  def then_i_see_my_vaccination_tallies_with_all_zero_values_with_default_batches
    rows = page.all(".nhsuk-table__row")
    expect(rows[1]).to have_content("Fluenz 0 #{@fluenz_batch.name} Change")
    expect(rows[2]).to have_content("Cervarix 0 #{@cervarix_batch.name} Change")
    expect(rows[3]).to have_content("Gardasil 0 Not set")
  end

  def and_i_click_on_the_expander_your_vaccinations_today
    find("span", text: "Your vaccinations today").click
  end
end
