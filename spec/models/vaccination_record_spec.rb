# frozen_string_literal: true

require "rails_helper"

describe VaccinationRecord do
  it "validates that the vaccine and the batch vaccines match" do
    patient_session = create(:patient_session)
    vaccine = create(:vaccine, :hpv)
    different_vaccine = create(:vaccine, :flu)
    batch = create(:batch, vaccine: different_vaccine)

    subject =
      build(
        :vaccination_record,
        administered: true,
        vaccine:,
        batch:,
        patient_session:
      )

    expect(subject).not_to be_valid
    expect(subject.errors[:batch_id]).to include(
      "Choose a batch of the #{vaccine.brand} vaccine"
    )
  end
end
