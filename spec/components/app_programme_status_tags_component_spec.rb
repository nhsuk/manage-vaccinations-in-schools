# frozen_string_literal: true

describe AppProgrammeStatusTagsComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(programme_statuses, outcome: :consent) }

  let(:menacwy_programme) { create(:programme, :menacwy) }
  let(:td_ipv_programme) { create(:programme, :td_ipv) }
  let(:flu_programme) { create(:programme, :flu) }

  let(:programme_statuses) do
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
