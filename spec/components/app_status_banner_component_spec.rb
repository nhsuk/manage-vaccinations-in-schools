require "rails_helper"

RSpec.describe AppStatusBannerComponent, type: :component do
  let(:patient_session) { create :patient_session }
  let(:component) { described_class.new(patient_session:) }
  let!(:rendered) { render_inline(component) }
  let(:triage_nurse_name) { patient_session.triage.last.user.full_name }
  let(:patient_name) { patient_session.patient.full_name }

  subject { page }

  prepend_before do
    patient_session.patient.update!(first_name: "Alya", last_name: "Merton")
  end

  context "state is added_to_session" do
    let(:patient_session) { create :patient_session, :added_to_session }

    it { should have_css(".nhsuk-card--blue") }
  end

  context "state is consent_given_triage_not_needed" do
    let(:patient_session) do
      create :patient_session, :consent_given_triage_not_needed
    end

    it { should have_css(".nhsuk-card--purple") }
    it { should have_css(".nhsuk-card__heading", text: "Consent given") }
    it { should have_text("#{patient_name} is ready to vaccinate") }
  end

  context "state is consent_given_triage_needed" do
    let(:patient_session) do
      create :patient_session, :consent_given_triage_needed
    end

    it { should have_css(".nhsuk-card--blue") }
    it { should have_css(".nhsuk-card__heading", text: "Needs triage") }
    it { should have_text("Responses to health questions need triage") }
  end

  context "state is consent_refused" do
    let(:patient_session) { create :patient_session, :consent_refused }

    it { should have_css(".nhsuk-card--orange") }
    it { should have_css(".nhsuk-card__heading", text: "Consent refused") }
    it { should have_text("Mum refused to give consent") }
  end

  context "state is triaged_do_not_vaccinate" do
    let(:patient_session) { create :patient_session, :triaged_do_not_vaccinate }

    it { should have_css(".nhsuk-card--red") }
    it { should have_css(".nhsuk-card__heading", text: "Could not vaccinate") }

    it "contains the correct explanation" do
      expect(page).to have_text(
        "A nurse decided that #{patient_name} should not be vaccinated."
      )
    end
  end

  context "state is triaged_kept_in_triage" do
    let(:patient_session) { create :patient_session, :triaged_kept_in_triage }

    it { should have_css(".nhsuk-card--blue") }
    it { should have_css(".nhsuk-card__heading", text: "Needs triage") }
    it { should have_text("Responses to health questions need triage") }
  end

  context "state is triaged_ready_to_vaccinate" do
    let(:patient_session) do
      create :patient_session, :triaged_ready_to_vaccinate
    end

    it { should have_css(".nhsuk-card--purple") }
    it { should have_css(".nhsuk-card__heading", text: "Safe to vaccinate") }
    it "explains who took the decision that the patient should be vaccinated" do
      expect(component.explanation).to eq(
        "Nurse #{triage_nurse_name} decided that #{patient_name} is safe to vaccinate."
      )
    end
  end

  context "state is unable_to_vaccinate" do
    let(:patient_session) { create :patient_session, :unable_to_vaccinate }

    it { should have_css(".nhsuk-card--red") }
    it { should have_css(".nhsuk-card__heading", text: "Could not vaccinate") }
    it "explains who took the decision that the patient should be vaccinated" do
      expect(component.explanation).to include(
        "Alya Merton had contraindications"
      )
    end
  end

  context "state is vaccinated" do
    let(:patient_session) { create :patient_session, :vaccinated }
    let(:vaccination_record) { patient_session.vaccination_records.first }
    let(:vaccine) { patient_session.session.campaign.vaccines.first }
    let(:location) { patient_session.session.location }
    let(:batch) { vaccine.batches.first }
    let(:date) { vaccination_record.recorded_at.to_fs(:nhsuk_date) }
    let(:time) { vaccination_record.recorded_at.to_fs(:time) }

    it { should have_css(".nhsuk-card--green") }
    it { should have_css(".nhsuk-card__heading", text: "Vaccinated") }
    it { should have_text("VaccineHPV (#{vaccine.brand}, #{batch.name})") }
    it { should have_text("SiteLeft arm") }
    it { should have_text("Date#{date}") }
    it { should have_text("Time#{time}") }
    it { should have_text("Location#{location.name}") }

    context "recorded_at is today" do
      let(:patient_session) do
        create(:patient_session, :vaccinated).tap do |ps|
          ps.vaccination_records.first.update(recorded_at: Time.zone.now)
        end
      end
      let(:date) { Time.zone.now.to_fs(:nhsuk_date) }

      it { should have_text("DateToday (#{date})") }
    end
  end
end
