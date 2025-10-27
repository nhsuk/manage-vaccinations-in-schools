# frozen_string_literal: true

describe AppProgrammeStatusTagsComponent do
  subject { render_inline(component) }

  let(:menacwy_programme) { create(:programme, :menacwy) }
  let(:mmr_programme) { create(:programme, :mmr) }
  let(:td_ipv_programme) { create(:programme, :td_ipv) }
  let(:flu_programme) { create(:programme, :flu) }

  context "for consent context" do
    let(:component) do
      described_class.new(status_by_programme, context: :consent)
    end

    let(:status_by_programme) do
      {
        flu_programme => {
          status: :given,
          vaccine_method: "nasal"
        },
        menacwy_programme => {
          status: :given
        },
        mmr_programme => {
          status: :given,
          without_gelatine: true
        },
        td_ipv_programme => {
          status: :refused
        }
      }
    end

    it { should have_content("FluConsent given for nasal spray") }
    it { should have_content("MenACWYConsent given") }
    it { should have_content("MMRConsent given for gelatine-free injection") }
    it { should have_content("Td/IPVConsent refused") }
  end

  context "for vaccination context" do
    let(:component) do
      described_class.new(status_by_programme, context: :vaccination)
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
