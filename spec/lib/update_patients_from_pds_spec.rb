# frozen_string_literal: true

describe UpdatePatientsFromPDS do
  subject(:call) { described_class.call(patients, priority:, queue:) }

  let(:patients) { Patient.order(:created_at) }
  let(:priority) { 0 }
  let(:queue) { :default }

  after { Settings.reload! }

  before do
    create_list(:patient, 2, pending_changes: { given_name: "New given name" })
    create_list(
      :patient,
      2,
      nhs_number: nil,
      pending_changes: {
        given_name: "New given name"
      }
    )
  end

  context "when disabled" do
    before { Settings.pds.enqueue_bulk_updates = false }

    it "queues no jobs" do
      expect { call }.not_to have_enqueued_job
    end
  end

  it "queues a job for each patient without an NHS number" do
    expect { call }.to have_enqueued_job(PatientNHSNumberLookupJob)
      .on_queue(:default)
      .exactly(2)
      .times.and have_enqueued_job(PatientNHSNumberLookupWithPendingChangesJob)
                 .on_queue(:default)
                 .exactly(4)
                 .times
  end

  it "queues a job for each patient with an NHS number" do
    expect { call }.to have_enqueued_job(PatientUpdateFromPDSJob)
      .on_queue(:default)
      .exactly(2)
      .times.and have_enqueued_job(PatientNHSNumberLookupWithPendingChangesJob)
                 .on_queue(:default)
                 .exactly(4)
                 .times
  end

  it "schedules the jobs with a gap between them" do
    freeze_time do
      # stree-ignore
      expect { call }.to have_enqueued_job(PatientUpdateFromPDSJob).at(
        Time.current
      ).and have_enqueued_job(PatientNHSNumberLookupWithPendingChangesJob).at(
        Time.current + 2.seconds
      ).and have_enqueued_job(PatientUpdateFromPDSJob).at(
        Time.current + 4.seconds
      ).and have_enqueued_job(PatientNHSNumberLookupWithPendingChangesJob).at(
        Time.current + 6.seconds
      ).and have_enqueued_job(PatientNHSNumberLookupJob).at(
        Time.current + 8.seconds
      ).and have_enqueued_job(PatientNHSNumberLookupWithPendingChangesJob).at(
        Time.current + 10.seconds
      ).and have_enqueued_job(PatientNHSNumberLookupJob).at(
        Time.current + 12.seconds
      ).and have_enqueued_job(PatientNHSNumberLookupWithPendingChangesJob).at(
        Time.current + 14.seconds
      )
    end
  end
end
