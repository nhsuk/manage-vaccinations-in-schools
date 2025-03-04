# frozen_string_literal: true

describe AppVaccinateFormComponent do
  subject(:rendered) { render_inline(component) }

  let(:heading) { "A Heading" }
  let(:body) { "A Body" }
  let(:programmes) { [create(:programme, :hpv)] }
  let(:session) { create(:session, :today, programmes:) }
  let(:vaccine) { programme.vaccines.first }
  let(:patient) do
    create(
      :patient,
      :consent_given_triage_not_needed,
      programmes:,
      given_name: "Hari"
    )
  end
  let(:patient_session) do
    create(:patient_session, :in_attendance, programmes:, patient:, session:)
  end

  let(:component) do
    described_class.new(
      patient_session:,
      programme: programmes.first,
      vaccinate_form: VaccinateForm.new
    )
  end

  before { patient_session.strict_loading!(false) }

  it { should have_css(".nhsuk-card") }

  it "has the correct heading" do
    expect(rendered).to have_css(
      ".nhsuk-card__heading",
      text: "Is Hari ready for their HPV vaccination?"
    )
  end

  it { should have_field("Yes") }
  it { should have_field("No") }

  describe "#render?" do
    subject(:render) { component.render? }

    context "patient is not ready for vaccination" do
      before do
        allow(patient_session).to receive(:next_step).and_return(:triage)
      end

      context "session is in progress" do
        let(:session) { create(:session, :today, programmes:) }

        it { should be(false) }
      end

      context "session is in the future" do
        let(:session) { create(:session, :scheduled, programmes:) }

        it { should be(false) }
      end
    end

    context "patient is ready for vaccination" do
      before do
        allow(patient_session).to receive(:next_step).and_return(:vaccinate)
      end

      context "session is progress" do
        let(:session) { create(:session, :today, programmes:) }

        it { should be(true) }
      end

      context "session is in the future" do
        let(:session) { create(:session, :scheduled, programmes:) }

        it { should be(false) }
      end
    end
  end
end
