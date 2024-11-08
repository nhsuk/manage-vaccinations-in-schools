# frozen_string_literal: true

describe DraftGillickAssessment do
  subject(:draft_gillick_assessment) do
    described_class.new(request_session:, current_user:, **attributes)
  end

  let(:request_session) { {} }
  let(:current_user) { create(:user) }

  let(:patient_session) { create(:patient_session) }

  let(:valid_competent_attributes) do
    {
      gillick_competent: true,
      notes: "Some notes.",
      patient_session_id: patient_session.id
    }
  end

  let(:valid_not_competent_attributes) do
    {
      gillick_competent: false,
      notes: "Some notes.",
      patient_session_id: patient_session.id
    }
  end

  let(:invalid_attributes) { {} }

  describe "validations" do
    context "on gillick step" do
      let(:attributes) { valid_competent_attributes }

      before { draft_gillick_assessment.wizard_step = :gillick }

      it do
        expect(draft_gillick_assessment).to allow_values(true, false).for(
          :gillick_competent
        ).on(:update)
      end
    end

    context "on notes step" do
      let(:attributes) { valid_competent_attributes }

      before { draft_gillick_assessment.wizard_step = :notes }

      it { should validate_presence_of(:notes).on(:update) }
    end
  end
end
