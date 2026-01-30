describe AppPatientSecondaryNavigationComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient:, current_user:) }

  let(:programme) { Programme.hpv }
  let(:session) { create(:session, programmes: [programme]) }
  let(:patient) { create(:patient, session:) }
  let(:current_user) { build(:user) }

  let(:allowed) { false }

  before do
    stub_authorization(
      allowed: allowed,
      klass: PatientPolicy,
      methods: %i[log?]
    )
  end

  context "when unauthorised" do
    it "renders nothing" do
      expect(rendered.text).to be_empty
    end
  end

  context "when authorised" do
    let(:allowed) { true }

    it "renders the navigation with child record tab" do
      expect(rendered.text).to include("Child record")
    end
  end
end
