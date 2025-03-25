#!frozen_string_literal: true

describe PipelineStats do
  subject(:diagram) { instance.render }

  let(:instance) { described_class.new(organisation:, programme:) }

  before do
    cohort_import = create(:cohort_import, organisation:)
    class_import = create(:class_import, organisation:)

    patient1 =
      create(
        :patient,
        :vaccinated,
        organisation:,
        year_group: 10,
        cohort_imports: [cohort_import]
      )
    create(:consent, :given, patient: patient1, organisation:, programme:)

    patient2 =
      create(
        :patient,
        :consent_given_triage_not_needed,
        :vaccinated,
        organisation:,
        year_group: 10,
        cohort_imports: [cohort_import],
        class_imports: [class_import]
      )
    create(
      :consent,
      :not_provided,
      patient: patient2,
      organisation:,
      programme:
    )

    create(
      :patient,
      :vaccinated,
      organisation:,
      year_group: 10,
      cohort_imports: [cohort_import],
      class_imports: [class_import]
    )

    patient3 =
      create(
        :patient,
        :triage_ready_to_vaccinate,
        :vaccinated,
        organisation:,
        year_group: 10,
        class_imports: [class_import]
      )
    create(:consent, :refused, patient: patient3, organisation:, programme:)

    create(:patient, organisation:, year_group: 10)
  end

  let(:organisation) { create(:organisation) }
  let(:programme) { Programme.hpv&.first || create(:programme, :hpv) }

  it "has stats" do
    expect(diagram).to eq <<~DIAGRAM
    sankey-beta
    Cohort Upload,Total Patients,3
    Class Upload,Total Patients,1
    Consent Forms,Total Patients,1
    Total Patients,Consent Given,1
    Total Patients,Consent Refused,1
    Total Patients,Consent Response Not Provided,1
    Total Patients,Without Consent Response,2
    DIAGRAM
  end
end
