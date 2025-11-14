# frozen_string_literal: true

describe AppProgrammeTagsComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(programmes) }

  let(:programmes) { [Programme.menacwy, Programme.td_ipv] }

  it { should have_content("MenACWY Td/IPV") }

  context "with unordered programmes" do
    let(:programmes) { [Programme.td_ipv, Programme.menacwy] }

    it { should have_content("MenACWY Td/IPV") }
  end
end
