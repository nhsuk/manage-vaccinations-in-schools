# frozen_string_literal: true

describe AppVaccineCriteriaLabelComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) do
    described_class.new(vaccine_criteria, programme:, context:)
  end

  let(:vaccine_criteria) do
    VaccineCriteria.new(programme:, vaccine_methods:, without_gelatine:)
  end

  let(:programme) { Programme.mmr }

  context "with heading context" do
    let(:context) { :heading }

    let(:vaccine_methods) { %w[injection] }
    let(:without_gelatine) { false }

    it { should have_content("Record MMR(V) vaccination") }

    context "with gelatine-free injection" do
      let(:without_gelatine) { true }

      it do
        expect(rendered).to have_content(
          "Record MMR(V) vaccination with gelatine-free injection"
        )
      end
    end
  end

  context "with vaccine type context" do
    let(:context) { :vaccine_type }

    let(:vaccine_methods) { %w[injection] }
    let(:without_gelatine) { false }

    it { should have_content("No preference for MMR") }

    context "with gelatine-free injection" do
      let(:without_gelatine) { true }

      it { should have_content("Gelatine-free vaccine only for MMR") }
    end
  end
end
