# frozen_string_literal: true

describe API::Testing::TeamsController do
  include ActiveJob::TestHelper

  before { Flipper.enable(:testing_api) }
  after { Flipper.disable(:testing_api) }

  around { |example| travel_to(Date.new(2025, 7, 31)) { example.run } }

  describe "DELETE" do
    let(:programmes) { [create(:programme, :hpv_all_vaccines)] }

    let(:team) do
      create(
        :team,
        :with_generic_clinic,
        ods_code: "R1L",
        workgroup: "r1l",
        programmes:
      )
    end

    let(:cohort_import) do
      create(
        :cohort_import,
        csv: fixture_file_upload("spec/fixtures/cohort_import/valid.csv"),
        team:
      )
    end

    let(:immunisation_import) do
      create(
        :immunisation_import,
        csv:
          fixture_file_upload(
            "spec/fixtures/immunisation_import/valid_hpv.csv"
          ),
        team:
      )
    end

    before do
      programmes.each do |programme|
        programme.vaccines.each do |vaccine|
          create_list(:batch, 4, team:, vaccine:)
        end
      end

      create(:school, urn: "123456", team:, programmes:) # to match cohort_import/valid.csv
      create(:school, urn: "110158", team:, programmes:) # to match valid_hpv.csv

      TeamSessionsFactory.call(team, academic_year: AcademicYear.current)

      cohort_import.process!
      CommitImportJob.drain
      immunisation_import.process!

      Patient.find_each do |patient|
        create(:notify_log_entry, :email, patient:, consent_form: nil)

        consent_form = create(:consent_form, session: Session.first)
        parent =
          patient.parents.first || create(:parent_relationship, patient:).parent
        create(
          :consent,
          :given,
          patient:,
          parent:,
          consent_form:,
          programme: programmes.first
        )
      end

      create(:school_move, :to_school, patient: Patient.first)
      create(:session_date, session: Session.first)
      create(:pre_screening, patient: Patient.first, session: Session.first)
    end

    it "deletes associated data" do
      expect { delete :destroy, params: { workgroup: "r1l" } }.to(
        change(Team, :count)
          .by(-1)
          .and(change(Subteam, :count).by(-1))
          .and(change(Session, :count).by(-3))
          .and(change(CohortImport, :count).by(-1))
          .and(change(ImmunisationImport, :count).by(-1))
          .and(change(NotifyLogEntry, :count).by(-3))
          .and(change(Parent, :count).by(-4))
          .and(change(Patient, :count).by(-3))
          .and(change(PatientLocation, :count).by(-3))
          .and(change(VaccinationRecord, :count).by(-9))
          .and(change(SessionDate, :count).by(-1))
      )
    end

    context "when keeping itself" do
      subject(:call) do
        delete :destroy, params: { workgroup: "r1l", keep_itself: "true" }
      end

      it "deletes associated data" do
        expect { call }.to(
          not_change(Team, :count)
            .and(not_change(Subteam, :count))
            .and(not_change(Session, :count))
            .and(change(CohortImport, :count).by(-1))
            .and(change(ImmunisationImport, :count).by(-1))
            .and(change(NotifyLogEntry, :count).by(-3))
            .and(change(Parent, :count).by(-4))
            .and(change(Patient, :count).by(-3))
            .and(change(PatientLocation, :count).by(-3))
            .and(change(VaccinationRecord, :count).by(-9))
            .and(change(SessionDate, :count).by(-1))
        )
      end
    end
  end
end
