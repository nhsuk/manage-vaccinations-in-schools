class AppActivityLogComponentPreview < ViewComponent::Preview
  def default
    setup

    render AppActivityLogComponent.new(patient_session)
  end

  private

  attr_reader :patient_session, :campaign, :session, :patient, :consents

  def setup
    @campaign = Campaign.first
    @session = @campaign.sessions.first
    @patient = FactoryBot.create(:patient)

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
      FactoryBot.create(:patient_session, patient: @patient, session: @session)
  end
end
