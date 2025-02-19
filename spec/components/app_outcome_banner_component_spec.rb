# frozen_string_literal: true

describe AppOutcomeBannerComponent do
  subject(:rendered) { render_inline(component) }

  let(:user) { create(:user) }
  let(:patient_session) { create(:patient_session) }
  let(:component) do
    described_class.new(
      patient_session:
        PatientSession.preload_for_status.find(patient_session.id),
      current_user: user
    )
  end
  let(:location_name) { patient_session.session.location.name }
  let(:patient_name) { patient_session.patient.full_name }

  prepend_before do
    patient_session.patient.update!(given_name: "Alya", family_name: "Merton")
  end

  context "state is unable_to_vaccinate" do
    let(:patient_session) { create(:patient_session, :unable_to_vaccinate) }

    it { should have_css(".app-card--red") }
    it { should have_css(".nhsuk-card__heading", text: "Could not vaccinate") }
    it { should have_text("MERTON, Alya has already had the vaccine") }
    it { should have_text("Location\n#{location_name}") }
  end

  context "triaged, not possible to vaccinate" do
    let(:patient_session) { create(:patient_session, :unable_to_vaccinate) }

    it { should have_css(".app-card--red") }
    it { should have_css(".nhsuk-card__heading", text: "Could not vaccinate") }
    it { should have_text("Reason\nMERTON, Alya has already had the vaccine") }
  end

  context "not triaged, not possible to vaccinate" do
    let(:patient_session) do
      create(:patient_session, :unable_to_vaccinate_and_had_no_triage)
    end

    it { should have_css(".app-card--red") }
    it { should have_css(".nhsuk-card__heading", text: "Could not vaccinate") }
    it { should have_text("Reason\nMERTON, Alya has already had the vaccine") }
  end

  context "state is vaccinated" do
    let(:programme) { create(:programme, :hpv) }
    let(:patient_session) { create(:patient_session, :vaccinated, programme:) }
    let(:vaccination_record) do
      patient_session.vaccination_records(programme:).first
    end
    let(:vaccine) { programme.vaccines.first }
    let(:location) { patient_session.session.location }
    let(:batch) { vaccine.batches.first }
    let(:date) { vaccination_record.performed_at.to_date.to_fs(:long) }
    let(:time) { vaccination_record.performed_at.to_fs(:time) }

    it { should have_css(".app-card--green") }
    it { should have_css(".nhsuk-card__heading", text: "Vaccinated") }
    it { should have_text("Vaccine\nHPV (#{vaccine.brand}, #{batch.name})") }
    it { should have_text("Site\nLeft arm") }
    it { should have_text("Date\nToday (#{date})") }
    it { should have_text("Time\n#{time}") }
    it { should have_text("Location\n#{location.name}") }

    context "vaccination was not administered today" do
      let(:date) { Time.zone.now - 2.days }
      let(:patient_session) do
        create(:patient_session, :vaccinated, programme:).tap do |ps|
          ps.strict_loading!(false)
          ps.vaccination_records(programme:).first.update!(performed_at: date)
        end
      end

      it { should have_text("Date\n#{date.to_date.to_fs(:long)}") }
    end

    context "when it's unknown who performed the vaccination" do
      before { vaccination_record.update!(performed_by_user: nil) }

      it { should have_text("Vaccinator\nUnknown") }
    end
  end

  context "state is triaged_do_not_vaccinate" do
    let(:patient_session) do
      create(:patient_session, :triaged_do_not_vaccinate, user:)
    end
    let(:vaccination_record) { patient_session.vaccination_records.first }
    let(:programme) { patient_session.programmes.first }
    let(:location) { patient_session.session.location }
    let(:triage) { patient_session.triages(programme:).first }
    let(:date) { triage.created_at.to_date.to_fs(:long) }

    it { should have_css(".app-card--red") }
    it { should have_css(".nhsuk-card__heading", text: "Could not vaccinate") }
    it { should have_text("Reason\nDo not vaccinate in programme") }
    it { should have_text("Date\nToday (#{date})") }
    it { should_not have_text("Location") }

    it do
      expect(rendered).to have_text(
        "Decided by\nYou (#{triage.performed_by.full_name})"
      )
    end

    context "triage decision was not recorded today" do
      let(:date) { Time.zone.now - 2.days }
      let(:patient_session) do
        create(:patient_session, :triaged_do_not_vaccinate).tap do |ps|
          ps
            .triages(programme: ps.programmes.first)
            .first
            .update!(created_at: date)
        end
      end

      it { should have_text("Date\n#{date.to_date.to_fs(:long)}") }
    end
  end
end
