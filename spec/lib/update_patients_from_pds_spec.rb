# frozen_string_literal: true

describe UpdatePatientsFromPDS do
  subject(:call) { described_class.call(patients, queue:) }

  let(:patients) { Patient.order(:created_at) }
  let(:queue) { :pds }

  after { Settings.reload! }

  before do
    create_list(:patient, 2)
    create_list(:patient, 2, nhs_number: nil)
  end

  context "when disabled" do
    before { Settings.pds.enqueue_bulk_updates = false }

    it "queues no jobs" do
      expect { call }.not_to have_enqueued_job
    end
  end

  it "queues a job for each patient without an NHS number" do
    expect { call }.to have_enqueued_job(PatientNHSNumberLookupJob)
      .on_queue(:pds)
      .exactly(2)
      .times
  end

  it "queues a job for each patient with an NHS number" do
    expect { call }.to have_enqueued_job(PatientUpdateFromPDSJob)
      .on_queue(:pds)
      .exactly(2)
      .times
  end

  context "when PDS cascading search is enabled" do
    before { Flipper.enable(:pds_cascading_search) }
    after { Flipper.disable(:pds_cascading_search) }

    it "queues PDSCascadingSearchJob for patients without an NHS number" do
      expect { call }.to have_enqueued_job(PDSCascadingSearchJob)
        .on_queue(:pds)
        .exactly(2)
        .times
    end

    it "does not queue PatientNHSNumberLookupJob for patients without an NHS number" do
      expect { call }.not_to have_enqueued_job(
        PatientNHSNumberLookupJob
      ).on_queue(:pds)
    end
  end
end
