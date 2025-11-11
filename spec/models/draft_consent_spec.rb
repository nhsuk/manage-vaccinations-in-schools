# frozen_string_literal: true

describe DraftConsent do
  subject(:draft_consent) do
    described_class.new(request_session:, current_user:, **attributes)
  end

  let(:team) { create(:team, :with_one_nurse, programmes: [programme]) }

  let(:request_session) { {} }
  let(:current_user) { team.users.first }

  let(:programme) { CachedProgramme.hpv }
  let(:session) { create(:session, team:, programmes: [programme]) }
  let(:patient) { create(:patient, session:) }

  let(:valid_given_attributes) do
    {
      notes: "Some notes.",
      response: "given",
      parent_email: "test@example.com",
      patient_id: patient.id,
      session_id: session.id,
      programme_type: programme.type
    }
  end

  let(:valid_given_nasal_attributes) do
    valid_given_attributes.merge(
      response: "given_nasal",
      injection_alternative: false
    )
  end

  let(:valid_given_injection_attributes) do
    valid_given_attributes.merge(response: "given_injection")
  end

  let(:valid_refused_attributes) do
    {
      response: "refused",
      notes: "Some notes.",
      parent_email: "test@example.com",
      patient_id: patient.id,
      session_id: session.id,
      programme_type: programme.type
    }
  end

  let(:invalid_attributes) { {} }

  describe "validations" do
    context "on the parent step" do
      let(:attributes) { { wizard_step: :parent_details } }

      it do
        expect(draft_consent).to validate_inclusion_of(
          :parent_relationship_type
        ).in_array(%w[father guardian mother other])
      end
    end

    context "when given" do
      let(:attributes) { valid_given_attributes }

      it { should be_valid }
    end

    context "when given nasal" do
      let(:attributes) { valid_given_nasal_attributes }

      it { should be_valid }
    end

    context "when given injection" do
      let(:attributes) do
        valid_given_attributes.merge(response: "given_injection")
      end

      it { should be_valid }
    end

    context "when refused" do
      let(:attributes) { valid_refused_attributes }

      it { should be_valid }
    end
  end

  describe "#write_to" do
    subject(:write_to) { draft_consent.write_to!(consent, triage_form:) }

    let(:consent) { Consent.new }
    let(:triage_form) { TriageForm.new }

    let(:attributes) { valid_given_attributes }

    it "sets the submitted at to today" do
      freeze_time do
        expect { write_to }.to change(consent, :submitted_at).from(nil).to(
          Time.current
        )
      end
    end

    context "when given nasal" do
      let(:attributes) { valid_given_nasal_attributes }

      it "sets the response to given" do
        freeze_time do
          expect { write_to }.to change(consent, :response).from(nil).to(
            "given"
          )
        end
      end
    end
  end

  describe "#reset_unused_attributes" do
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

    context "when given flu via nasal" do
      let(:attributes) { valid_given_nasal_attributes }

      it "sets vaccine_methods to nasal" do
        expect { save! }.to change(draft_consent, :vaccine_methods).to(
          %w[nasal]
        )
      end

      context "when injection allowed as an alternative" do
        let(:attributes) do
          valid_given_nasal_attributes.merge(injection_alternative: true)
        end

        it "sets vaccine_methods to nasal and injection" do
          expect { save! }.to change(draft_consent, :vaccine_methods).to(
            %w[nasal injection]
          )
        end
      end

      context "when rejecting injection alternative" do
        let(:attributes) do
          valid_given_nasal_attributes.merge(injection_alternative: false)
        end

        it "sets vaccine_methods to nasal and injection" do
          expect { save! }.to change(draft_consent, :vaccine_methods).to(
            %w[nasal]
          )
        end
      end
    end

    context "when given flu injection" do
      let(:attributes) { valid_given_injection_attributes }

      it "sets vaccine_methods to injection" do
        expect { save! }.to change(draft_consent, :vaccine_methods).to(
          %w[injection]
        )
      end
    end

    context "when refused" do
      let(:attributes) do
        valid_refused_attributes.merge(
          health_answers: [{ "id" => "0" }],
          vaccine_methods: %w[nasal],
          injection_alternative: true
        )
      end

      it "clears the health answers" do
        expect { save! }.to change(draft_consent, :health_answers).to([])
      end

      it "clears the vaccine methods" do
        expect { save! }.to change(draft_consent, :vaccine_methods).to([])
      end

      it "clears injection_alternative" do
        expect { save! }.to change(draft_consent, :injection_alternative).to(
          nil
        )
      end
    end

    context "when notes not required" do
      let(:attributes) do
        valid_refused_attributes.merge(
          reason_for_refusal: "personal_choice",
          notes: "Some notes."
        )
      end

      it "clears the notes" do
        expect { save! }.to change(draft_consent, :notes).to("")
      end
    end
  end
end
