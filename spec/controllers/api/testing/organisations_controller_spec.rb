# frozen_string_literal: true

describe API::Testing::OrganisationsController do
  before { Flipper.enable(:testing_api) }
  after { Flipper.disable(:testing_api) }

  describe "DELETE" do
    let(:programmes) { [create(:programme, :hpv_all_vaccines)] }

    let(:organisation) do
      create(:organisation, :with_generic_clinic, ods_code: "R1L", programmes:)
    end

    let(:cohort_import) do
      create(
        :cohort_import,
        csv: fixture_file_upload("spec/fixtures/cohort_import/valid.csv"),
        organisation:
      )
    end

    let(:immunisation_import) do
      create(
        :immunisation_import,
        csv:
          fixture_file_upload(
            "spec/fixtures/immunisation_import/valid_hpv.csv"
          ),
        organisation:
      )
    end

    before do
      programmes.each do |programme|
        programme.vaccines.each do |vaccine|
          create_list(:batch, 4, organisation:, vaccine:)
        end
      end

      OrganisationSessionsFactory.call(
        organisation,
        academic_year: AcademicYear.current
      )

      create(:school, urn: "123456", organisation:, programmes:) # to match cohort_import/valid.csv
      create(:school, urn: "110158", organisation:, programmes:) # to match valid_hpv.csv

      cohort_import.process!
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
      create(:pre_screening, patient_session: PatientSession.first)
    end

    it "deletes associated data" do
      expect { delete :destroy, params: { ods_code: "r1l" } }.to(
        change(Organisation, :count)
          .by(-1)
          .and(change(Subteam, :count).by(-1))
          .and(change(Session, :count).by(-1))
          .and(change(CohortImport, :count).by(-1))
          .and(change(ImmunisationImport, :count).by(-1))
          .and(change(NotifyLogEntry, :count).by(-3))
          .and(change(Parent, :count).by(-4))
          .and(change(Patient, :count).by(-3))
          .and(change(PatientSession, :count).by(-3))
          .and(change(VaccinationRecord, :count).by(-11))
          .and(change(SessionDate, :count).by(-1))
      )
    end

    context "when keeping itself" do
      subject(:call) do
        delete :destroy, params: { ods_code: "r1l", keep_itself: "true" }
      end

      it "deletes associated data" do
        expect { call }.to(
          not_change(Organisation, :count)
            .and(not_change(Subteam, :count))
            .and(not_change(Session, :count))
            .and(change(CohortImport, :count).by(-1))
            .and(change(ImmunisationImport, :count).by(-1))
            .and(change(NotifyLogEntry, :count).by(-3))
            .and(change(Parent, :count).by(-4))
            .and(change(Patient, :count).by(-3))
            .and(change(PatientSession, :count).by(-3))
            .and(change(VaccinationRecord, :count).by(-11))
            .and(change(SessionDate, :count).by(-1))
        )
      end
    end
  end
end
