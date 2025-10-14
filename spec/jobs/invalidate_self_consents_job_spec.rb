# frozen_string_literal: true

describe InvalidateSelfConsentsJob do
  subject(:perform_now) { described_class.perform_now }

  let(:academic_year) { AcademicYear.current }
  let(:patient) { consent.patient }
  let(:programme) { consent.programme }
  let(:team) { consent.team }

  context "with parental consent from yesterday" do
    let(:consent) { create(:consent, academic_year:, created_at: 1.day.ago) }

    before { create(:patient_vaccination_status, patient:, programme:) }

    it "does not invalidate the consent" do
      expect { perform_now }.not_to(change { consent.reload.invalidated? })
    end

    context "with triage" do
      let(:triage) do
        create(
          :triage,
          :safe_to_vaccinate,
          academic_year:,
          created_at: 1.day.ago,
          team:,
          programme:,
          patient:
        )
      end

      it "does not invalidate the triage" do
        expect { perform_now }.not_to(change { triage.reload.invalidated? })
      end
    end
  end

  context "with parental consent from today" do
    let(:consent) { create(:consent, academic_year:) }

    before { create(:patient_vaccination_status, patient:, programme:) }

    it "does not invalidate the consent" do
      expect { perform_now }.not_to(change { consent.reload.invalidated? })
    end

    context "with triage" do
      let(:triage) do
        create(
          :triage,
          :safe_to_vaccinate,
          academic_year:,
          team:,
          programme:,
          patient:
        )
      end

      it "does not invalidate the triage" do
        expect { perform_now }.not_to(change { triage.reload.invalidated? })
      end
    end
  end

  context "with self-consent from yesterday" do
    let(:consent) do
      create(:consent, :self_consent, academic_year:, created_at: 1.day.ago)
    end

    before { create(:patient_vaccination_status, patient:, programme:) }

    it "invalidates the consent" do
      expect { perform_now }.to change { consent.reload.invalidated? }.from(
        false
      ).to(true)
    end

    context "with triage" do
      let(:triage) do
        create(
          :triage,
          :safe_to_vaccinate,
          academic_year:,
          created_at: 1.day.ago,
          team:,
          programme:,
          patient:
        )
      end

      it "invalidates the triage" do
        expect { perform_now }.to change { triage.reload.invalidated? }.from(
          false
        ).to(true)
      end
    end

    context "if the patient was vaccinated" do
      before do
        create(
          :vaccination_record,
          team:,
          programme:,
          patient:,
          created_at: 1.day.ago
        )

        patient.vaccination_statuses.update_all(status: :vaccinated)
      end

      it "does not invalidate the consent" do
        expect { perform_now }.not_to(change { consent.reload.invalidated? })
      end

      context "with triage" do
        let(:triage) do
          create(
            :triage,
            :safe_to_vaccinate,
            academic_year:,
            created_at: 1.day.ago,
            team:,
            programme:,
            patient:
          )
        end

        it "does not invalidate the triage" do
          expect { perform_now }.not_to(change { triage.reload.invalidated? })
        end
      end
    end
  end

  context "with self-consent from today" do
    let(:consent) { create(:consent, :self_consent, academic_year:) }

    before { create(:patient_vaccination_status, patient:, programme:) }

    it "does not invalidate the consent" do
      expect { perform_now }.not_to(change { consent.reload.invalidated? })
    end

    context "with triage" do
      let(:triage) do
        create(
          :triage,
          :safe_to_vaccinate,
          academic_year:,
          team:,
          programme:,
          patient:
        )
      end

      it "does not invalidate the triage" do
        expect { perform_now }.not_to(change { triage.reload.invalidated? })
      end
    end
  end

  context "with two programmes, parental consent for one and self-consent for the other" do
    let(:parent_programme) { create(:programme, :flu) }
    let(:self_programme) { create(:programme, :hpv) }

    let(:team) { create(:team, programmes: [parent_programme, self_programme]) }

    let(:patient) { create(:patient) }

    let!(:self_consent) do
      create(
        :consent,
        :self_consent,
        patient:,
        academic_year:,
        created_at: 1.day.ago,
        programme: self_programme,
        team:
      )
    end
    let!(:parent_consent) do
      create(
        :consent,
        patient:,
        academic_year:,
        created_at: 1.day.ago,
        programme: parent_programme,
        team:
      )
    end

    before do
      create(:patient_vaccination_status, patient:, programme: self_programme)
      create(:patient_vaccination_status, patient:, programme: parent_programme)
    end

    it "does not invalidate the parent consent" do
      expect { perform_now }.not_to(
        change { parent_consent.reload.invalidated? }
      )
    end

    it "invalidates the self-consent" do
      expect { perform_now }.to change {
        self_consent.reload.invalidated?
      }.from(false).to(true)
    end
  end
end
