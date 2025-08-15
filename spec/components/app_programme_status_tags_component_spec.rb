# frozen_string_literal: true

describe AppProgrammeStatusTagsComponent do
  subject { render_inline(component) }

  let(:menacwy_programme) { create(:programme, :menacwy) }
  let(:td_ipv_programme) { create(:programme, :td_ipv) }
  let(:flu_programme) { create(:programme, :flu) }

  context "for consent outcome" do
    let(:component) do
      described_class.new(status_by_programme, outcome: :consent)
    end

    let(:status_by_programme) do
      {
        menacwy_programme => {
          status: :given
        },
        td_ipv_programme => {
          status: :refused
        },
        flu_programme => {
          status: :given,
          vaccine_methods: %w[nasal injection]
        }
      }
    end

    it { should have_content("MenACWYConsent given") }
    it { should have_content("Td/IPVConsent refused") }
    it { should have_content("FluConsent givenNasal spray") }
  end

  context "for programme outcome" do
    let(:component) do
      described_class.new(status_by_programme, outcome: :programme)
    end

    let(:status_by_programme) do
      {
        menacwy_programme => {
          status: :vaccinated
        },
        td_ipv_programme => {
          status: :none_yet,
          latest_session_status: :unwell
        }
      }
    end

    it { should have_content("MenACWYVaccinated") }
    it { should have_content("Td/IPVNo outcomeUnwell") }
  end
end
