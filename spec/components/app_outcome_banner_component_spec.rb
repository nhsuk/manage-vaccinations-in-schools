# frozen_string_literal: true

describe AppOutcomeBannerComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  let(:user) { create :user }
  let(:patient_session) { create :patient_session, user: }
  let(:component) { described_class.new(patient_session:, current_user: user) }
  let(:triage_nurse_name) { patient_session.triage.last.performed_by.full_name }
  let(:patient_name) { patient_session.patient.full_name }

  prepend_before do
    patient_session.patient.update!(first_name: "Alya", last_name: "Merton")
  end

  context "state is unable_to_vaccinate" do
    let(:patient_session) { create :patient_session, :unable_to_vaccinate }

    it { should have_css(".app-card--red") }
    it { should have_css(".nhsuk-card__heading", text: "Could not vaccinate") }
    it { should have_text("Alya Merton has already had the vaccine") }

    it do
      expect(subject).to have_text(
        "Location\n#{patient_session.session.location.name}"
      )
    end
  end

  context "state is vaccinated" do
    let(:campaign) { create(:campaign, :hpv) }
    let(:patient_session) do
      create(
        :patient_session,
        :vaccinated,
        user:,
        session_attributes: {
          campaign:
        }
      )
    end
    let(:vaccination_record) { patient_session.vaccination_records.first }
    let(:vaccine) { patient_session.session.campaign.vaccines.first }
    let(:location) { patient_session.session.location }
    let(:batch) { vaccine.batches.first }
    let(:date) { vaccination_record.recorded_at.to_date.to_fs(:long) }
    let(:time) { vaccination_record.recorded_at.to_fs(:time) }

    it { should have_css(".app-card--green") }
    it { should have_css(".nhsuk-card__heading", text: "Vaccinated") }
    it { should have_text("Vaccine\nHPV (#{vaccine.brand}, #{batch.name})") }
    it { should have_text("Site\nLeft arm") }
    it { should have_text("Date\n#{date}") }
    it { should have_text("Time\n#{time}") }
    it { should have_text("Location\n#{location.name}") }

    context "recorded_at is today" do
      let(:patient_session) do
        create(:patient_session, :vaccinated).tap do |ps|
          ps.vaccination_records.first.update(recorded_at: Time.zone.now)
        end
      end
      let(:date) { Time.zone.today.to_fs(:long) }

      it { should have_text("Date\nToday (#{date})") }
    end
  end

  context "state is triaged_do_not_vaccinate" do
    let(:patient_session) do
      create :patient_session, :triaged_do_not_vaccinate, user:
    end
    let(:vaccination_record) { patient_session.vaccination_records.first }
    let(:location) { patient_session.session.location }
    let(:triage) { patient_session.triage.first }
    let(:date) { triage.created_at.to_date.to_fs(:long) }

    it { should have_css(".app-card--red") }
    it { should have_css(".nhsuk-card__heading", text: "Could not vaccinate") }
    it { should have_text("Reason\nDo not vaccinate in campaign") }
    it { should have_text("Date\nToday (#{date})") }
    it { should_not have_text("Location") }

    it do
      expect(rendered).to have_text(
        "Decided by\nYou (#{triage.performed_by.full_name})"
      )
    end

    context "recorded_at is not today" do
      let(:date) { Time.zone.now - 2.days }
      let(:patient_session) do
        create(:patient_session, :triaged_do_not_vaccinate).tap do |ps|
          ps.triage.first.update!(created_at: date)
        end
      end

      it { should have_text("Date\n#{date.to_date.to_fs(:long)}") }
    end
  end
end
