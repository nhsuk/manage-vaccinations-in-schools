# frozen_string_literal: true

describe AppProgrammeTagsComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(programmes) }

  let(:programmes) { [CachedProgramme.menacwy, CachedProgramme.td_ipv] }

  it { should have_content("MenACWY Td/IPV") }

  context "with unordered programmes" do
    let(:programmes) { [CachedProgramme.td_ipv, CachedProgramme.menacwy] }

    it { should have_content("MenACWY Td/IPV") }
  end
end
