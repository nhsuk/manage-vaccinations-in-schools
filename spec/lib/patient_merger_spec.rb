# frozen_string_literal: true

describe PatientMerger do
  describe "#call" do
    subject(:call) do
      # Intentionally call this method as we would in a controller because
      # we were finding bugs when called like this but not on its own.
      Audited
        .audit_class
        .as_user(user) do
          described_class.call(
            to_keep:
              Patient.includes(parent_relationships: :parent).find(
                patient_to_keep.id
              ),
            to_destroy:
              Patient.includes(parent_relationships: :parent).find(
                patient_to_destroy.id
              )
          )
        end
    end

    let(:user) { create(:user) }

    let(:programme) { create(:programme) }
    let(:session) { create(:session, programme:) }

    let!(:patient_to_keep) { create(:patient) }
    let!(:patient_to_destroy) { create(:patient) }

    let(:access_log_entry) do
      create(:access_log_entry, patient: patient_to_destroy)
    end
    let(:consent) { create(:consent, patient: patient_to_destroy, programme:) }
    let(:consent_notification) do
      create(
        :consent_notification,
        :request,
        patient: patient_to_destroy,
        programme:
      )
    end
    let(:gillick_assessment) do
      create(:gillick_assessment, :competent, patient_session:)
    end
    let(:notify_log_entry) do
      create(:notify_log_entry, :email, patient: patient_to_destroy)
    end
    let(:parent_relationship) do
      create(:parent_relationship, patient: patient_to_destroy)
    end
    let(:patient_session) do
      create(:patient_session, session:, patient: patient_to_destroy)
    end
    let(:pre_screening) do
      create(:pre_screening, :allows_vaccination, patient_session:)
    end
    let(:school_move) do
      create(:school_move, :to_school, patient: patient_to_destroy)
    end
    let(:school_move_log_entry) do
      create(:school_move_log_entry, patient: patient_to_destroy)
    end
    let(:duplicate_school_move) do
      create(:school_move, patient: patient_to_keep, school: school_move.school)
    end
    let(:session_notification) do
      create(
        :session_notification,
        :school_reminder,
        patient: patient_to_destroy
      )
    end
    let(:triage) { create(:triage, patient: patient_to_destroy, programme:) }
    let(:vaccination_record) do
      create(
        :vaccination_record,
        patient: patient_to_destroy,
        session:,
        programme:
      )
    end

    it "destroys one of the patients" do
      expect { call }.to change(Patient, :count).by(-1)
      expect { patient_to_destroy.reload }.to raise_error(
        ActiveRecord::RecordNotFound
      )
    end

    it "moves access log entries" do
      expect { call }.to change { access_log_entry.reload.patient }.to(
        patient_to_keep
      )
    end

    it "moves consents" do
      expect { call }.to change { consent.reload.patient }.to(patient_to_keep)
    end

    it "moves consent notifications" do
      expect { call }.to change { consent_notification.reload.patient }.to(
        patient_to_keep
      )
    end

    it "moves gillick assessments" do
      expect { call }.to change { gillick_assessment.reload.patient }.to(
        patient_to_keep
      )
    end

    it "moves notify log entries" do
      expect { call }.to change { notify_log_entry.reload.patient }.to(
        patient_to_keep
      )
    end

    it "moves parent relationships" do
      expect { call }.to change { parent_relationship.reload.patient }.to(
        patient_to_keep
      )
    end

    it "moves patient sessions" do
      expect { call }.to change { patient_session.reload.patient }.to(
        patient_to_keep
      )
    end

    it "moves pre-screenings" do
      expect { call }.to change { pre_screening.reload.patient }.to(
        patient_to_keep
      )
    end

    it "moves school moves" do
      expect { call }.to change { school_move.reload.patient }.to(
        patient_to_keep
      )
    end

    it "moves school move log entries" do
      expect { call }.to change { school_move_log_entry.reload.patient }.to(
        patient_to_keep
      )
    end

    it "deletes duplicate school moves" do
      expect { call }.not_to change(duplicate_school_move, :patient)
      expect { school_move.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "moves session notifications" do
      expect { call }.to change { session_notification.reload.patient }.to(
        patient_to_keep
      )
    end

    it "moves triages" do
      expect { call }.to change { triage.reload.patient }.to(patient_to_keep)
    end

    it "moves vaccination records" do
      expect { call }.to change { vaccination_record.reload.patient }.to(
        patient_to_keep
      )
    end

    context "when parent is already associated with patient to keep" do
      before do
        create(
          :parent_relationship,
          parent: parent_relationship.parent,
          patient: patient_to_keep
        )
      end

      it "destroys the relationship with the patient to destroy" do
        expect { call }.to change(ParentRelationship, :count).by(-1)
        expect { parent_relationship.reload }.to raise_error(
          ActiveRecord::RecordNotFound
        )
      end
    end

    it "doesn't change the cohort" do
      expect { call }.not_to(change { patient_to_keep.reload.organisation })
    end

    context "if the patient to keep is not in the cohort" do
      let(:organisation) { create(:organisation) }

      let(:patient_to_keep) { create(:patient, organisation: nil) }
      let(:patient_to_destroy) { create(:patient, organisation:) }

      it "adds the patient back in to the cohort" do
        expect { call }.to change { patient_to_keep.reload.organisation }.to(
          organisation
        )
      end
    end
  end
end
