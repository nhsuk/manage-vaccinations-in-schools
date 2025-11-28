# frozen_string_literal: true

describe StatusGenerator::Programme do
  subject(:generator) do
    described_class.new(
      programme:,
      academic_year: AcademicYear.current,
      patient:,
      patient_locations:
        patient.patient_locations.includes(
          location: :location_programme_year_groups
        ),
      consents: patient.consents,
      triages: patient.triages,
      attendance_record: patient.attendance_records.first,
      vaccination_records:
        patient.vaccination_records.order(performed_at: :desc)
    )
  end

  let(:programme) { Programme.sample }
  let(:session) { create(:session, programmes: [programme]) }
  let(:patient) { create(:patient, session:) }

  context "when already vaccinated" do
    let(:programme) { Programme.hpv }

    let!(:vaccination_record) do
      create(:vaccination_record, :already_had, patient:, programme:)
    end

    its(:status) { should be(:vaccinated_already) }
    its(:date) { should eq(vaccination_record.performed_at.to_date) }
    its(:dose_sequence) { should be_nil }
    its(:vaccine_methods) { should be_empty }
    its(:without_gelatine) { should be_nil }
  end

  context "when fully vaccinated" do
    let(:programme) { Programme.hpv }

    let!(:vaccination_record) do
      create(:vaccination_record, patient:, programme:)
    end

    its(:status) { should be(:vaccinated_fully) }
    its(:date) { should eq(vaccination_record.performed_at.to_date) }
    its(:dose_sequence) { should be_nil }
    its(:vaccine_methods) { should be_empty }
    its(:without_gelatine) { should be_nil }
  end

  context "when partially vaccinated" do
    let(:programme) { Programme.mmr }

    let!(:vaccination_record) do
      create(:vaccination_record, patient:, programme:)
    end

    its(:status) { should be(:needs_consent_no_response) }
    its(:date) { should eq(vaccination_record.performed_at.to_date) }
    its(:dose_sequence) { should be_nil }
    its(:vaccine_methods) { should be_nil }
    its(:without_gelatine) { should be_nil }

    context "with consent for the next dose" do
      before { create(:consent, :given, patient:, programme:) }

      its(:status) { should be(:due) }
      its(:date) { should eq(vaccination_record.performed_at.to_date) }
      its(:vaccine_methods) { should contain_exactly("injection") }
      its(:without_gelatine) { should be(false) }
    end
  end

  context "when the child is unwell" do
    before { create(:consent, :given, patient:, programme:) }

    let!(:vaccination_record) do
      create(:vaccination_record, :unwell, patient:, programme:)
    end

    its(:status) { should be(:cannot_vaccinate_unwell) }
    its(:date) { should eq(vaccination_record.performed_at.to_date) }
    its(:vaccine_methods) { should contain_exactly("injection") }
    its(:without_gelatine) { should be(false) }

    context "on a different day" do
      let!(:vaccination_record) do
        create(:vaccination_record, :unwell, :yesterday, patient:, programme:)
      end

      its(:status) { should be(:due) }
      its(:date) { should eq(vaccination_record.performed_at.to_date) }
    end
  end

  context "when the child refused" do
    before { create(:consent, :given, patient:, programme:) }

    let!(:vaccination_record) do
      create(:vaccination_record, :refused, patient:, programme:)
    end

    its(:status) { should be(:cannot_vaccinate_refused) }
    its(:date) { should eq(vaccination_record.performed_at.to_date) }
    its(:vaccine_methods) { should contain_exactly("injection") }
    its(:without_gelatine) { should be(false) }

    context "on a different day" do
      let!(:vaccination_record) do
        create(:vaccination_record, :unwell, :yesterday, patient:, programme:)
      end

      its(:status) { should be(:due) }
      its(:date) { should eq(vaccination_record.performed_at.to_date) }
    end
  end

  context "when contraindicated" do
    before { create(:consent, :given, patient:, programme:) }

    let!(:vaccination_record) do
      create(:vaccination_record, :contraindicated, patient:, programme:)
    end

    its(:status) { should be(:cannot_vaccinate_contraindicated) }
    its(:date) { should eq(vaccination_record.performed_at.to_date) }
    its(:vaccine_methods) { should contain_exactly("injection") }
    its(:without_gelatine) { should be(false) }

    context "on a different day" do
      let!(:vaccination_record) do
        create(:vaccination_record, :unwell, :yesterday, patient:, programme:)
      end

      its(:status) { should be(:due) }
      its(:date) { should eq(vaccination_record.performed_at.to_date) }
    end
  end

  context "when the child was marked as absent" do
    before { create(:consent, :given, patient:, programme:) }

    let!(:attendance_record) do
      create(:attendance_record, :absent, patient:, session:)
    end

    its(:status) { should be(:cannot_vaccinate_absent) }
    its(:date) { should eq(attendance_record.date) }
    its(:vaccine_methods) { should contain_exactly("injection") }
    its(:without_gelatine) { should be(false) }

    context "on a different day" do
      let!(:attendance_record) do
        create(:attendance_record, :absent, :yesterday, patient:)
      end

      its(:status) { should be(:due) }
      its(:date) { should eq(attendance_record.date) }
    end
  end

  context "when triaged as delay" do
    before do
      create(:consent, :given, patient:, programme:)
      create(
        :triage,
        :delay_vaccination,
        patient:,
        programme:,
        delay_vaccination_until: Date.tomorrow
      )
    end

    its(:status) { should be(:cannot_vaccinate_delay_vaccination) }
    its(:date) { should eq(Date.tomorrow) }
    its(:dose_sequence) { should be_nil }
    its(:vaccine_methods) { should contain_exactly("injection") }
    its(:without_gelatine) { should be(false) }
  end

  context "when triaged as invite to clinic" do
    before do
      create(:consent, :given, patient:, programme:)
      create(:triage, :invite_to_clinic, patient:, programme:)
    end

    its(:status) { should be(:needs_triage) }
    its(:date) { should be_nil }
    its(:dose_sequence) { should be_nil }
    its(:vaccine_methods) { should be_nil }
    its(:without_gelatine) { should be_nil }
  end

  context "when triaged as do not vaccinated" do
    before do
      create(:consent, :given, patient:, programme:)
      create(:triage, :do_not_vaccinate, patient:, programme:)
    end

    its(:status) { should be(:cannot_vaccinate_do_not_vaccinate) }
    its(:date) { should be_nil }
    its(:dose_sequence) { should be_nil }
    its(:vaccine_methods) { should be_nil }
    its(:without_gelatine) { should be_nil }
  end

  context "when needs triage" do
    before { create(:consent, :given, :needing_triage, patient:, programme:) }

    its(:status) { should be(:needs_triage) }
    its(:date) { should be_nil }
    its(:dose_sequence) { should be_nil }
    its(:vaccine_methods) { should be_nil }
    its(:without_gelatine) { should be_nil }
  end

  context "when consent is refused" do
    before { create(:consent, :refused, patient:, programme:) }

    its(:status) { should be(:has_refusal_consent_refused) }
    its(:date) { should be_nil }
    its(:dose_sequence) { should be_nil }
    its(:vaccine_methods) { should be_nil }
    its(:without_gelatine) { should be_nil }
  end

  context "when consent is conflicting" do
    before do
      create(:consent, :refused, patient:, programme:)
      create(:consent, :given, patient:, programme:, parent: create(:parent))
    end

    its(:status) { should be(:has_refusal_consent_conflicts) }
    its(:date) { should be_nil }
    its(:dose_sequence) { should be_nil }
    its(:vaccine_methods) { should be_nil }
    its(:without_gelatine) { should be_nil }
  end

  context "when consent is needed" do
    its(:status) { should be(:needs_consent_no_response) }
    its(:date) { should be_nil }
    its(:dose_sequence) { should be_nil }
    its(:vaccine_methods) { should be_nil }
    its(:without_gelatine) { should be_nil }
  end

  context "when not eligible" do
    let(:patient) { create(:patient, year_group: 20) }

    its(:status) { should be(:not_eligible) }
    its(:date) { should be_nil }
    its(:dose_sequence) { should be_nil }
    its(:vaccine_methods) { should be_nil }
    its(:without_gelatine) { should be_nil }
  end
end
