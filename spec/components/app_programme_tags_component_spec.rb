# frozen_string_literal: true

describe AppProgrammeTagsComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(programmes) }

  let(:programmes) do
    [create(:programme, :menacwy), create(:programme, :td_ipv)]
  end

  it { should have_content("MenACWY Td/IPV") }

  context "with unordered programmes" do
    let(:programmes) do
      [create(:programme, :td_ipv), create(:programme, :menacwy)]
    end

    it { should have_content("MenACWY Td/IPV") }
  end
end
