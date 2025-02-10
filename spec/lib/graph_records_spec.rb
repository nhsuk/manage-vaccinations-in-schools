describe GraphRecords do
  subject(:graph) { described_class.new.graph(patients: [patient]) }

  let!(:programme) { create(:programme, :hpv) }
  let!(:organisation) { create(:organisation, programmes: [programme]) }
  let!(:session) { create(:session, organisation:, programmes: [programme]) }
  let!(:class_import) { create(:class_import, session:) }
  let!(:cohort_import) { create(:cohort_import, organisation:) }
  let!(:parent) do
    create(
      :parent,
      class_imports: [class_import],
      cohort_imports: [cohort_import]
    )
  end
  let!(:patient) do
    create(
      :patient,
      parents: [parent],
      session:,
      organisation:,
      programme:,
      class_imports: [class_import],
      cohort_imports: [cohort_import]
    )
  end
  let!(:consent) do
    create(:consent, :given, patient:, parent:, organisation:, programme:)
  end

  it { should start_with "flowchart TB" }

  it "generates the graph" do
    expect(graph).to contain_exactly(
      "flowchart TB",
      "  classDef patient_focused fill:#c2e598,stroke:#000,stroke-width:3px",
      "  classDef parent fill:#faa0a0",
      "  classDef consent fill:#fffaa0",
      "  classDef class_import fill:#7fd7df",
      "  classDef cohort_import fill:#a2d2ff",
      "  patient-#{patient.id}:::patient_focused",
      "  parent-#{parent.id}:::parent",
      "  consent-#{consent.id}:::consent",
      "  class_import-#{class_import.id}:::class_import",
      "  cohort_import-#{cohort_import.id}:::cohort_import",
      "  patient-#{patient.id} --> parent-#{parent.id}",
      "  consent-#{consent.id} --> parent-#{parent.id}",
      "  class_import-#{class_import.id} --> parent-#{parent.id}",
      "  cohort_import-#{cohort_import.id} --> parent-#{parent.id}",
      "  patient-#{patient.id} --> consent-#{consent.id}",
      "  class_import-#{class_import.id} --> patient-#{patient.id}",
      "  cohort_import-#{cohort_import.id} --> patient-#{patient.id}"
    )
  end
end
