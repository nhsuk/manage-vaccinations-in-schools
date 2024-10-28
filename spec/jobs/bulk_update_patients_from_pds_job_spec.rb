# frozen_string_literal: true

describe BulkUpdatePatientsFromPDSJob do
  subject(:perform_now) { described_class.perform_now }

  let!(:invalidated_patient) { create(:patient, :invalidated) }
  let!(:deceased_patient) { create(:patient, :deceased) }
  let!(:restricted_patient) { create(:patient, :restricted) }
  let!(:recently_updated_patient) do
    create(:patient, updated_from_pds_at: Time.current)
  end
  let!(:not_recently_updated_patient) do
    create(:patient, updated_from_pds_at: 3.days.ago)
  end
  let!(:never_updated_patient) { create(:patient, updated_from_pds_at: nil) }

  it "only queues jobs for the approriate patients" do
    expect { perform_now }.to have_enqueued_job(
      PatientUpdateFromPDSJob
    ).exactly(3).times
  end

  it "doesn't queue a job for the invalidated patient" do
    expect { perform_now }.not_to have_enqueued_job(
      PatientUpdateFromPDSJob
    ).with(invalidated_patient)
  end

  it "doesn't queue a job for the deceased patient" do
    expect { perform_now }.not_to have_enqueued_job(
      PatientUpdateFromPDSJob
    ).with(deceased_patient)
  end

  it "doesn't queue a job for the recently updated patient" do
    expect { perform_now }.not_to have_enqueued_job(
      PatientUpdateFromPDSJob
    ).with(recently_updated_patient)
  end

  it "queues a job for the restricted patient" do
    expect { perform_now }.to have_enqueued_job(PatientUpdateFromPDSJob).with(
      restricted_patient
    )
  end

  it "queues a job for the not recently updated patient" do
    expect { perform_now }.to have_enqueued_job(PatientUpdateFromPDSJob).with(
      not_recently_updated_patient
    )
  end

  it "queues a job for the never updated patient" do
    expect { perform_now }.to have_enqueued_job(PatientUpdateFromPDSJob).with(
      never_updated_patient
    )
  end
end
