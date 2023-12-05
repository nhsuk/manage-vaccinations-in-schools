require "rails_helper"

RSpec.describe AppVaccinateFormComponent, type: :component do
  let(:heading) { "A Heading" }
  let(:body) { "A Body" }
  let(:patient_session) { create :patient_session }
  let(:vaccination_record) { VaccinationRecord.new }
  let(:url) { "/vaccinate" }
  let(:component) do
    described_class.new(patient_session:, url:, vaccination_record:)
  end
  let(:rendered) { render_inline(component) }

  subject { page }

  before { rendered }

  it { should have_css(".nhsuk-card") }

  it "has the correct heading" do
    should have_css(
             "h2.nhsuk-card__heading",
             text: "Did they get the HPV vaccine?"
           )
  end

  it { should have_field("Yes, they got the HPV vaccine") }
  it { should have_field("No, they did not get it") }
end
