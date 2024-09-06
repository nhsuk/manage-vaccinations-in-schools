# frozen_string_literal: true

describe ApplicationMailer, type: :mailer do
  subject { described_class.new }

  let(:team) do
    create(
      :team,
      email: "team@email.com",
      name: "Teamy McTeamface",
      phone: "01234567890",
      reply_to_id: "notify-reply-to-id"
    )
  end
  let(:location) { create(:location, :school, name: "Hogwarts") }
  let(:programme) { create(:programme, :hpv, team:) }
  let(:session) do
    create(:session, programme:, location:, date: Date.new(2100, 1, 1))
  end
  let(:parent) { create(:parent, name: "Parent Doe", email: "foo@bar.com") }
  let(:patient) do
    create(:patient, first_name: "John", last_name: "Doe", parent:)
  end
  let(:patient_session) { create(:patient_session, patient:, session:) }

  describe "#opts" do
    it "returns correct options" do
      expect(subject.send(:opts, patient_session)).to eq(
        {
          to: "foo@bar.com",
          reply_to_id: "notify-reply-to-id",
          personalisation: {
            full_and_preferred_patient_name: "John Doe",
            location_name: "Hogwarts",
            long_date: "Friday 1 January",
            parent_name: "Parent Doe",
            short_date: "1 January",
            short_patient_name: "John",
            short_patient_name_apos: "John's",
            team_email: "team@email.com",
            team_name: "Teamy McTeamface",
            team_phone: "01234567890",
            vaccination: "HPV vaccination"
          }
        }
      )
    end
  end
end
