require "rails_helper"

RSpec.describe SessionRemindersBatchJob, type: :job do
  before { ActionMailer::Base.deliveries.clear }

  it "sends emails to all patients' parents" do
    patient = create(:patient)
    session = create(:session, patients: [patient], date: 1.day.from_now)

    expect { described_class.perform_now(session) }.to send_email(
      to: patient.parent_email
    )

    expect(ActionMailer::Base.deliveries.count).to eq(1)
  end
end
