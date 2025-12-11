# frozen_string_literal: true

describe DataMigration::CreateClinicNotifications do
  subject(:call) { described_class.call }

  before { create(:session_notification, :school_reminder) }

  let!(:clinic_initial_invitation) do
    create(:session_notification, :clinic_initial_invitation)
  end

  let!(:clinic_subsequent_invitation) do
    create(:session_notification, :clinic_subsequent_invitation)
  end

  it "creates suitable clinic notifications" do
    expect { call }.to change(ClinicNotification, :count).by(2)

    initial_invitation = ClinicNotification.initial_invitation.sole
    expect(initial_invitation.academic_year).to eq(
      clinic_initial_invitation.session.academic_year
    )
    expect(initial_invitation.programme_types).to eq(
      clinic_initial_invitation.session.programme_types
    )
    expect(initial_invitation.team_id).to eq(
      clinic_initial_invitation.session.team_id
    )
    expect(initial_invitation.sent_at).to eq(clinic_initial_invitation.sent_at)

    subsequent_invitation = ClinicNotification.subsequent_invitation.sole
    expect(subsequent_invitation.academic_year).to eq(
      clinic_subsequent_invitation.session.academic_year
    )
    expect(subsequent_invitation.programme_types).to eq(
      clinic_subsequent_invitation.session.programme_types
    )
    expect(subsequent_invitation.team_id).to eq(
      clinic_subsequent_invitation.session.team_id
    )
    expect(subsequent_invitation.sent_at).to eq(
      clinic_subsequent_invitation.sent_at
    )
  end
end
