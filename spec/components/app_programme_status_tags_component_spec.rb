# frozen_string_literal: true

describe AppProgrammeStatusTagsComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(programme_statuses, outcome: :consent) }

  let(:menacwy_programme) { create(:programme, :menacwy) }
  let(:td_ipv_programme) { create(:programme, :td_ipv) }

  let(:programme_statuses) do
    { menacwy_programme => :given, td_ipv_programme => :refused }
  end

  it { should have_content("MenACWYConsent given") }
  it { should have_content("Td/IPVConsent refused") }
end
