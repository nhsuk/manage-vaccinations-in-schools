# frozen_string_literal: true

describe PDSLookupJob, type: :job do
  it "calls the NHS::PDS::Patient.find_by" do
    allow(NHS::PDS::Patient).to receive(:find_by)

    described_class.perform_now(given: "name")

    expect(NHS::PDS::Patient).to have_received(:find_by).with(given: "name")
  end
end
