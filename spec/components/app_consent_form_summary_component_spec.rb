# frozen_string_literal: true

describe AppConsentFormSummaryComponent do
  subject { page }

  let(:component) do
    described_class.new(
      name: "Jane Smith",
      relationship: "Mum",
      contact: {
        phone: "07987654321",
        email: "jane@example.com"
      },
      response: {
        text: "Consent refused (online)",
        timestamp: Time.zone.local(2024, 3, 1, 14, 23, 0)
      },
      refusal_reason: {
        reason: "already vaccinated",
        notes: "Vaccinated at the GP"
      }
    )
  end

  before { render_inline(component) }

  it { should have_text("Jane Smith") }
  it { should have_text("Mum") }
  it { should have_text("07987654321") }
  it { should have_text("jane@example.com") }
  it { should have_text("Consent refused (online)") }
  it { should have_text("1 March 2024 at 2:23pm") }

  it do
    expect(subject).to have_text(
      "Refusal reasonAlready vaccinated\nVaccinated at the GP"
    )
  end

  context "with only mandatory fields" do
    let(:component) do
      described_class.new(
        name: "Jane Smith",
        response: {
          text: "Consent given (online)",
          timestamp: Time.zone.local(2024, 3, 1, 14, 23, 0)
        }
      )
    end

    it { should have_text("Jane Smith") }
    it { should have_text("Consent given (online)") }
    it { should have_text("1 March 2024 at 2:23pm") }
    it { should_not have_text("Relationship") }
    it { should_not have_text("Contact") }
    it { should_not have_text("Refusal reason") }
  end

  context "with only refusal reason" do
    let(:component) do
      described_class.new(
        name: "Jane Smith",
        response: {
          text: "Consent refused (online)",
          timestamp: Time.zone.local(2024, 3, 1, 14, 23, 0)
        },
        refusal_reason: {
          reason: "Personal choice"
        }
      )
    end

    it { should have_text("Jane Smith") }
    it { should have_text("Refusal reasonPersonal choice") }
  end

  context "with multiple responses" do
    let(:component) do
      described_class.new(
        name: "Jane Smith",
        response: [
          {
            text: "Consent given (online)",
            timestamp: Time.zone.local(2024, 3, 1, 14, 23, 0)
          },
          {
            text: "Consent refused (online)",
            timestamp: Time.zone.local(2024, 3, 2, 14, 24, 0)
          }
        ]
      )
    end

    it { should have_text("Jane Smith") }
    it { should have_text("Consent given (online)") }
    it { should have_text("1 March 2024 at 2:23pm") }
    it { should have_text("Consent refused (online)") }
    it { should have_text("2 March 2024 at 2:24pm") }
  end

  context "with response being an array with one element" do
    let(:component) do
      described_class.new(
        name: "Jane Smith",
        response: [
          {
            text: "Consent given (online)",
            timestamp: Time.zone.local(2024, 3, 1, 14, 23, 0)
          }
        ]
      )
    end

    it { should have_text("1 March 2024 at 2:23pm") }
    it { should_not have_css("li") }
  end
end
