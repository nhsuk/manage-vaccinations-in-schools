require "rails_helper"

RSpec.describe AppVaccinateFormComponent, type: :component do
  let(:heading) { "A Heading" }
  let(:body) { "A Body" }
  let(:session) { create :session, :in_progress }
  let(:patient_session) do
    create :patient_session, :consent_given_triage_not_needed, session:
  end
  let(:vaccination_record) { VaccinationRecord.new }
  let(:url) { "/vaccinate" }
  let(:component) do
    described_class.new(patient_session:, url:, vaccination_record:)
  end
  let!(:rendered) { render_inline(component) }

  subject { page }

  it { should have_css(".nhsuk-card") }

  it "has the correct heading" do
    should have_css(
             "h2.nhsuk-card__heading",
             text: "Did they get the HPV vaccine?"
           )
  end

  it { should have_field("Yes, they got the HPV vaccine") }
  it { should have_field("No, they did not get it") }

  describe "render?" do
    subject { component.render? }

    context "patient is not ready for vaccination" do
      before do
        allow(patient_session).to receive(:next_step).and_return(:triage)
      end

      context "session is in progress" do
        let(:session) { create :session, :in_progress }

        it { should be_falsey }
      end

      context "session is in the future" do
        let(:session) { create :session, :in_future }

        it { should be_falsey }
      end
    end

    context "patient is ready for vaccination" do
      before do
        allow(patient_session).to receive(:next_step).and_return(:vaccinate)
      end

      context "session is progress" do
        let(:session) { create :session, :in_progress }

        it { should be_truthy }
      end

      context "session is in the future" do
        let(:session) { create :session, :in_future }

        it { should be_falsey }
      end
    end
  end
end
