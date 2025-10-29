# frozen_string_literal: true

describe AppVaccineCriteriaLabelComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) do
    described_class.new(vaccine_criteria, programme:, context:)
  end

  let(:vaccine_criteria) do
    VaccineCriteria.new(vaccine_methods:, without_gelatine:)
  end

  let(:programme) { create(:programme, :mmr) }

  context "with heading context" do
    let(:context) { :heading }

    let(:vaccine_methods) { %w[injection] }
    let(:without_gelatine) { false }

    it { should have_content("Record MMR vaccination") }

    context "with gelatine-free vaccine" do
      let(:without_gelatine) { true }

      it do
        expect(rendered).to have_content(
          "Record MMR vaccination with gelatine-free injection"
        )
      end
    end
  end

  context "with vaccine type context" do
    let(:context) { :vaccine_type }

    let(:vaccine_methods) { %w[injection] }
    let(:without_gelatine) { false }

    it { should have_content("Either for MMR") }

    context "with gelatine-free vaccine" do
      let(:without_gelatine) { true }

      it { should have_content("Gelatine-free injection for MMR") }
    end
  end
end
