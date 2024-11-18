# frozen_string_literal: true

describe DraftConsent do
  subject(:draft_consent) do
    described_class.new(request_session:, current_user:, **attributes)
  end

  let(:organisation) do
    create(:organisation, :with_one_nurse, programmes: [programme])
  end

  let(:request_session) { {} }
  let(:current_user) { organisation.users.first }

  let(:patient_session) { create(:patient_session, programme:) }
  let(:programme) { create(:programme, :hpv) }

  let(:valid_given_attributes) do
    {
      notes: "Some notes.",
      response: "given",
      patient_session_id: patient_session.id,
      programme_id: programme.id
    }
  end

  let(:valid_refused_attributes) do
    {
      response: "refused",
      notes: "Some notes.",
      patient_session_id: patient_session.id,
      programme_id: programme.id
    }
  end

  let(:invalid_attributes) { {} }

  describe "validations" do
    context "when given" do
      let(:attributes) { valid_given_attributes }

      it { should be_valid }
    end

    context "when refused" do
      let(:attributes) { valid_refused_attributes }

      it { should be_valid }
    end
  end

  describe "#reset_unused_fields" do
    subject(:save!) { draft_consent.save! }

    context "when given" do
      let(:attributes) do
        valid_given_attributes.merge(reason_for_refusal: "personal_choice")
      end

      it "clears the notes" do
        expect { save! }.to change(draft_consent, :notes).to("")
      end

      it "clears the reason for refusal" do
        expect { save! }.to change(draft_consent, :reason_for_refusal).to(nil)
      end

      it "sets the health answers" do
        expect { save! }.to change(draft_consent, :health_answers).from([])
      end
    end

    context "when refused" do
      let(:attributes) do
        valid_refused_attributes.merge(health_answers: [{ "id" => "0" }])
      end

      it "clears the health answers" do
        expect { save! }.to change(draft_consent, :health_answers).to([])
      end
    end
  end
end
