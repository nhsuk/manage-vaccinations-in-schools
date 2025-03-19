# frozen_string_literal: true

describe GraphRecords do
  subject(:graph) { described_class.new.graph(patient: patient.id) }

  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  let!(:programmes) { [create(:programme, :hpv)] }
  let!(:organisation) { create(:organisation, programmes:) }
  let!(:session) { create(:session, organisation:, programmes:) }
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
      programmes:,
      class_imports: [class_import],
      cohort_imports: [cohort_import]
    )
  end
  let!(:consent) do
    create(
      :consent,
      :given,
      patient:,
      parent:,
      organisation:,
      programme: programmes.first
    )
  end

  def non_breaking_text(text)
    # Insert non-breaking spaces and hyphens to prevent Mermaid from breaking the line
    text.gsub(" ", "&nbsp;").gsub("-", "#8209;")
  end

  it { should start_with "flowchart TB" }

  it "generates the graph" do
    expect(graph).to contain_exactly(
      "flowchart TB",
      "  classDef patient_focused fill:#469990,color:white,stroke:#000,stroke-width:3px",
      "  classDef parent fill:#e6194B,color:white,stroke:#000",
      "  classDef consent fill:#aaffc3,color:black,stroke:#000",
      "  classDef cohort_import fill:#4363d8,color:white,stroke:#000",
      "  classDef class_import fill:#000075,color:white,stroke:#000",
      "  classDef patient_session fill:#e6194B,color:white,stroke:#000",
      "  classDef session fill:#fabed4,color:black,stroke:#000",
      "  classDef location fill:#3cb44b,color:white,stroke:#000",
      "  patient-#{patient.id}[\"Patient #{patient.id}<br><span style=\"font-size:10px\"><i>Patient.find(" \
        "#{patient.id})</i></span><br><span style=\"font-size:10px\"><i>puts&nbsp;GraphRecords.new.graph(patient:" \
        "&nbsp;#{patient.id})</i></span>\"]:::patient_focused",
      "  parent-#{parent.id}[\"Parent #{parent.id}<br><span style=\"font-size:10px\"><i>Parent.find(#{parent.id})</i>" \
        "</span><br><span style=\"font-size:10px\"><i>puts&nbsp;GraphRecords.new.graph(parent:&nbsp;#{parent.id})</i>" \
        "</span>\"]:::parent",
      "  consent-#{consent.id}[\"Consent #{consent.id}<br><span style=\"font-size:10px\"><i>Consent.find(" \
        "#{consent.id})</i></span><br><span style=\"font-size:10px\"><i>puts&nbsp;GraphRecords.new.graph(consent:" \
        "&nbsp;#{consent.id})</i></span><br><span style=\"font-size:14px\">response:&nbsp;#{consent.response}" \
        "</span><br><span style=\"font-size:14px\">route:&nbsp;#{consent.route}</span><br><span style=\"" \
        "font-size:14px\">created_at:&nbsp;2024#8209;02#8209;01&nbsp;00:00:00&nbsp;+0000</span>\"]:::consent",
      "  cohort_import-#{cohort_import.id}[\"Cohort import #{cohort_import.id}<br><span style=\"font-size:10px\"><i>" \
        "CohortImport.find(#{cohort_import.id})</i></span><br><span style=\"font-size:10px\"><i>puts&nbsp;" \
        "GraphRecords.new.graph(cohort_import:&nbsp;#{cohort_import.id})</i></span><br><span style=\"font-size:14px" \
        "\">csv_filename:&nbsp;#{non_breaking_text(cohort_import.csv_filename)}</span><br><span style=\"" \
        "font-size:14px\">created_at:&nbsp;2024#8209;02#8209;01&nbsp;00:00:00&nbsp;+0000</span><br><span " \
        "style=\"font-size:14px\">status:&nbsp;#{cohort_import.status}</span><br><span style=\"font-size:" \
        "14px\">rows_count:&nbsp;#{cohort_import.rows_count}</span>\"]:::cohort_import",
      "  class_import-#{class_import.id}[\"Class import #{class_import.id}<br><span style=\"font-size:10px\"><i>" \
        "ClassImport.find(#{class_import.id})</i></span><br><span style=\"font-size:10px\"><i>puts&nbsp;GraphRecords" \
        ".new.graph(class_import:&nbsp;#{class_import.id})</i></span><br><span style=\"font-size:14px\">" \
        "csv_filename:&nbsp;#{non_breaking_text(class_import.csv_filename)}</span><br><span style=\"font-size:" \
        "14px\">created_at:&nbsp;2024#8209;02#8209;01&nbsp;00:00:00&nbsp;+0000</span><br><span style=\"" \
        "font-size:14px\">status:&nbsp;#{class_import.status}</span><br><span style=\"font-size:14px\">" \
        "rows_count:&nbsp;#{class_import.rows_count}</span><br><span style=\"font-size:14px\">" \
        "year_groups:&nbsp;#{non_breaking_text(class_import.year_groups.to_s)}</span>\"]:::class_import",
      "  patient_session-#{patient.patient_sessions.first.id}[\"Patient session #{patient.patient_sessions.first.id}" \
        "<br><span style=\"font-size:10px\"><i>PatientSession.find(#{patient.patient_sessions.first.id})</i></span>" \
        "<br><span style=\"font-size:10px\"><i>puts&nbsp;GraphRecords.new.graph(patient_session:&nbsp;" \
        "#{patient.patient_sessions.first.id})</i></span>\"]:::patient_session",
      "  session-#{session.id}[\"Session #{session.id}<br><span style=\"font-size:10px\"><i>Session.find(" \
        "#{session.id})</i></span><br><span style=\"font-size:10px\"><i>puts&nbsp;GraphRecords.new.graph(session:" \
        "&nbsp;#{session.id})</i></span><br><span style=\"font-size:14px\">clinic?:&nbsp;#{session.clinic?}</span>" \
        "\"]:::session",
      "  location-#{session.location.id}[\"Location #{session.location.id}<br><span style=\"font-size:10px\"><i>" \
        "Location.find(#{session.location.id})</i></span><br><span style=\"font-size:10px\"><i>puts&nbsp;GraphRecords" \
        ".new.graph(location:&nbsp;#{session.location.id})</i></span><br><span style=\"font-size:14px\">name:&nbsp;" \
        "#{non_breaking_text(session.location.name)}</span>\"]:::location",
      "  patient-#{patient.id} --> parent-#{parent.id}",
      "  consent-#{consent.id} --> parent-#{parent.id}",
      "  patient-#{patient.id} --> consent-#{consent.id}",
      "  cohort_import-#{cohort_import.id} --> parent-#{parent.id}",
      "  class_import-#{class_import.id} --> parent-#{parent.id}",
      "  cohort_import-#{cohort_import.id} --> patient-#{patient.id}",
      "  class_import-#{class_import.id} --> patient-#{patient.id}",
      "  patient_session-#{patient.patient_sessions.first.id} --> patient-#{patient.id}",
      "  session-#{session.id} --> patient_session-#{patient.patient_sessions.first.id}",
      "  location-#{session.location.id} --> session-#{session.id}",
      "  location-#{session.location.id} --> patient-#{patient.id}"
    )
  end

  context "when node limit is exceeded" do
    subject(:graph_exceeded) do
      described_class.new(
        node_limit: 1 # A very low limit to trigger recursion limit early
      ).graph(patients: [patient])
    end

    it "returns a fallback Mermaid diagram with the error message in a red box" do
      error_message =
        "Recursion limit of 1 nodes has been exceeded. Try restricting the graph."
      expect(graph_exceeded).to include("flowchart TB")
      # Assuming the error node is named `error` we check its content.
      expect(graph_exceeded.join).to include("error[#{error_message}]")
      expect(graph_exceeded.join).to include(
        "style error fill:#f88,stroke:#f00,stroke-width:2px"
      )
    end
  end
end
