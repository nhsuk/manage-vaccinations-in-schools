class AppActivityLogComponentPreview < ViewComponent::Preview
  def default
    setup

    render AppActivityLogComponent.new(patient_session)
  end

  private

  attr_reader :patient_session, :campaign, :session, :patient, :consents

  def setup
    @team = Team.first
    @campaign = @team.campaigns.first
    @user = @team.users.first
    @session = @campaign.sessions.first
    @location = @session.location
    @patient = FactoryBot.create(:patient, location: @location)

    @consents = [
      FactoryBot.create(
        :consent,
        :given,
        :from_mum,
        campaign: @campaign,
        patient: @patient,
        parent_name: "Jane Doe",
        recorded_at: Time.zone.parse("2024-05-30 12:00")
      ),
      FactoryBot.create(
        :consent,
        :refused,
        :from_dad,
        campaign: @campaign,
        patient: @patient,
        parent_name: "John Doe",
        recorded_at: Time.zone.parse("2024-05-30 13:00")
      )
    ]

    @patient_session =
      FactoryBot.create(
        :patient_session,
        patient: @patient,
        session: @session,
        created_at: Time.zone.parse("2024-05-29 12:00")
      )

    @triage = [
      FactoryBot.create(
        :triage,
        :kept_in_triage,
        patient_session: @patient_session,
        created_at: Time.zone.parse("2024-05-30 14:00"),
        user: @user
      ),
      FactoryBot.create(
        :triage,
        :do_not_vaccinate,
        patient_session: @patient_session,
        created_at: Time.zone.parse("2024-05-30 14:10"),
        user: @user
      ),
      FactoryBot.create(
        :triage,
        :delay_vaccination,
        patient_session: @patient_session,
        created_at: Time.zone.parse("2024-05-30 14:20"),
        user: @user
      ),
      FactoryBot.create(
        :triage,
        :vaccinate,
        patient_session: @patient_session,
        created_at: Time.zone.parse("2024-05-30 14:30"),
        user: @user
      )
    ]

    @vaccination_records = [
      FactoryBot.create(
        :vaccination_record,
        patient_session: @patient_session,
        created_at: Time.zone.parse("2024-05-31 12:00"),
        user: @user
      )
    ]
  end
end
