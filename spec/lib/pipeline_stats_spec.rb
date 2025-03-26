#!frozen_string_literal: true

describe PipelineStats do
  subject(:diagram) { instance.render }

  let(:instance) { described_class.new }
  let(:organisation) { create(:organisation, programmes: [programme]) }
  let(:programme) { Programme.hpv&.first || create(:programme, :hpv) }
  let(:flu_programme) { Programme.flu&.first || create(:programme, :flu) }

  before do
    [
      organisation,
      create(:organisation, programmes: [flu_programme])
    ].each do |organisation|
      session =
        create(:session, organisation:, programmes: organisation.programmes)
      cohort_import = create(:cohort_import, organisation:)
      class_import = create(:class_import, organisation:, session:)
      programme = organisation.programmes.first

      patient1 =
        create(
          :patient,
          :vaccinated,
          organisation:,
          session:,
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
          session:,
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
        session:,
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
          session:,
          year_group: 10,
          class_imports: [class_import]
        )
      create(:consent, :refused, patient: patient3, organisation:, programme:)

      create(:patient, organisation:, session:, year_group: 10)
    end
  end

  it "produces stats for all organisations and programmes" do
    expect(diagram).to eq <<~DIAGRAM
      sankey-beta
      Cohort Upload,Total Patients,6
      Class Upload,Total Patients,2
      Consent Forms,Total Patients,2
      Total Patients,Consent Given,2
      Total Patients,Consent Refused,2
      Total Patients,Consent Response Not Provided,2
      Total Patients,Without Consent Response,4
    DIAGRAM
  end

  context "given an organisation" do
    let(:instance) { described_class.new(organisations: [organisation]) }

    it "produces stats for the given organisation and all programmes" do
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

  context "given a programme" do
    let(:instance) { described_class.new(programmes: [flu_programme]) }

    it "produces stats for all organisations but only that programme" do
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
end
