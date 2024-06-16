# == Schema Information
#
# Table name: consent_forms
#
#  id                        :bigint           not null, primary key
#  address_line_1            :string
#  address_line_2            :string
#  address_postcode          :string
#  address_town              :string
#  common_name               :text
#  contact_injection         :boolean
#  contact_method            :integer
#  contact_method_other      :text
#  date_of_birth             :date
#  first_name                :text
#  gp_name                   :string
#  gp_response               :integer
#  health_answers            :jsonb            not null
#  last_name                 :text
#  parent_email              :string
#  parent_name               :string
#  parent_phone              :string
#  parent_relationship       :integer
#  parent_relationship_other :string
#  reason                    :integer
#  reason_notes              :text
#  recorded_at               :datetime
#  response                  :integer
#  use_common_name           :boolean
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  consent_id                :bigint
#  parent_id                 :bigint
#  session_id                :bigint           not null
#
# Indexes
#
#  index_consent_forms_on_consent_id  (consent_id)
#  index_consent_forms_on_parent_id   (parent_id)
#  index_consent_forms_on_session_id  (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (consent_id => consents.id)
#  fk_rails_...  (parent_id => parents.id)
#  fk_rails_...  (session_id => sessions.id)
#
require "rails_helper"

RSpec.describe ConsentForm, type: :model do
  describe "Validations" do
    let(:use_common_name) { false }
    let(:response) { nil }
    let(:reason) { nil }
    let(:gp_response) { nil }
    let(:health_answers) { [] }
    let(:session) { build(:session) }
    subject(:consent_form) do
      build(
        :consent_form,
        form_step:,
        use_common_name:,
        response:,
        reason:,
        gp_response:,
        health_answers:,
        session:
      )
    end

    context "when form_step is nil" do
      let(:form_step) { nil }

      it { should validate_presence_of(:first_name).on(:update) }
      it { should validate_presence_of(:last_name).on(:update) }
      it { should validate_presence_of(:date_of_birth).on(:update) }
      it { should_not validate_presence_of(:is_this_their_school).on(:update) }
      it { should validate_presence_of(:response).on(:update) }
    end

    context "when form_step is :name" do
      let(:form_step) { :name }

      it { should validate_presence_of(:first_name).on(:update) }
      it { should validate_presence_of(:last_name).on(:update) }

      context "when use_common_name is true" do
        let(:use_common_name) { true }

        it { should validate_presence_of(:common_name).on(:update) }
      end
    end

    context "when form_step is :date_of_birth" do
      let(:form_step) { :date_of_birth }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:first_name).on(:update) }
      end

      it { should validate_presence_of(:date_of_birth).on(:update) }
      # it { should validate_comparison_of(:date_of_birth)
      #       .is_less_than(Time.zone.today)
      #       .is_greater_than_or_equal_to(22.years.ago.to_date)
      #       .is_less_than_or_equal_to(3.years.ago.to_date)
      #       .on(:update) }
    end

    context "when form_step is :school" do
      let(:form_step) { :school }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:first_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
      end

      it { should validate_presence_of(:is_this_their_school).on(:update) }
      it do
        should validate_inclusion_of(:is_this_their_school).in_array(
                 %w[yes no]
               ).on(:update)
      end
    end

    context "when form_step is :parent" do
      let(:form_step) { :parent }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:first_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
      end

      it { should_not validate_presence_of(:is_this_their_school).on(:update) }
    end

    context "when form_step is :consent" do
      let(:form_step) { :consent }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:first_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
      end

      it { should validate_presence_of(:response).on(:update) }
    end

    context "when form_step is :reason" do
      let(:response) { "refused" }
      let(:form_step) { :reason }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:first_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
      end

      it { should validate_presence_of(:reason).on(:update) }
    end

    context "when form_step is :reason_notes" do
      let(:response) { "refused" }
      let(:reason) { "medical_reasons" }
      let(:form_step) { :reason_notes }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:first_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
      end

      it { should validate_presence_of(:reason_notes).on(:update) }
    end

    context "when form_step is :injection" do
      # currently injection alternative only offered during flu campaign
      let(:session) { build(:session, campaign: build(:campaign, :flu)) }

      let(:response) { "refused" }
      let(:reason) { "contains_gelatine" }
      let(:form_step) { :injection }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:first_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
        it { should validate_presence_of(:reason).on(:update) }
      end

      # This prints a warning because boolean fields always get converted to
      # false when they are blank. As such we can't check for this validation.
      # it do
      #   should validate_inclusion_of(:contact_injection).in_array(
      #            [true, false]
      #          ).on(:update)
      # end
    end

    context "when form_step is :gp" do
      let(:response) { "given" }
      let(:form_step) { :gp }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:first_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
      end

      it { should validate_presence_of(:gp_response).on(:update) }

      context "when gp_response is 'yes'" do
        let(:gp_response) { "yes" }

        it { should validate_presence_of(:gp_name).on(:update) }
      end
    end

    context "when form_step is :address" do
      let(:response) { "given" }
      let(:form_step) { :address }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:first_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
        it { should validate_presence_of(:gp_response).on(:update) }
      end

      it { should validate_presence_of(:address_line_1).on(:update) }
      it { should validate_presence_of(:address_town).on(:update) }
      it { should validate_presence_of(:address_postcode).on(:update) }

      it do
        should_not allow_value("invalid").for(:address_postcode).on(:update)
      end
    end

    context "when form_step is :health_question" do
      let(:response) { "given" }
      let(:gp_response) { "yes" }
      let(:form_step) { :health_question }
      let(:health_answers) do
        [
          HealthAnswer.new(
            id: 0,
            question: "Has your child been diagnosed with asthma?",
            next_question: 2,
            follow_up_question: 1
          ),
          HealthAnswer.new(
            id: 1,
            question: "Have they taken oral steroids in the last 2 weeks?",
            next_question: 2
          ),
          HealthAnswer.new(
            id: 2,
            question:
              "Has your child had a flu vaccination in the last 5 months?"
          )
        ]
      end

      describe "validations from previous steps" do
        it { should validate_presence_of(:first_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
        it { should validate_presence_of(:gp_response).on(:update) }
        it { should validate_presence_of(:address_line_1).on(:update) }
        it { should validate_presence_of(:address_town).on(:update) }
        it { should validate_presence_of(:address_postcode).on(:update) }
      end

      it "is valid if the default health answers have responses" do
        health_answers[0].response = "no"
        health_answers[2].response = "no"

        consent_form.save # rubocop:disable Rails/SaveBang
        expect(consent_form).to be_valid
      end

      it "is invalid if health answers do not have responses" do
        consent_form.save # rubocop:disable Rails/SaveBang
        expect(consent_form).to_not be_valid
      end

      it "checks follow-up questions if necessary" do
        health_answers[0].response = "yes"
        health_answers[0].notes = "for the tests"
        health_answers[2].response = "no"

        consent_form.save # rubocop:disable Rails/SaveBang
        expect(consent_form).to_not be_valid
      end

      context "health_question_number is set" do
        it "only validates the given health answer" do
          consent_form.health_question_number = 1
          consent_form.health_answers[1].response = "no"

          consent_form.save # rubocop:disable Rails/SaveBang
          expect(consent_form).to be_valid
        end
      end
    end
  end

  describe "#full_name" do
    it "returns the full name as a string" do
      consent_form = build(:consent_form, first_name: "John", last_name: "Doe")
      expect(consent_form.full_name).to eq("John Doe")
    end
  end

  describe "#form_steps" do
    it "does not ask for reason for refusal when patient gives consent" do
      consent_form = build(:consent_form, response: "given")
      expect(consent_form.form_steps).not_to include(:reason)
      expect(consent_form.form_steps).not_to include(:injection)
    end

    context "for a flu campaign, when patient refuses consent" do
      let(:session) { build(:session, campaign: build(:campaign, :flu)) }

      it "offers an injection alternative if the child hasn't received vaccine elsewhere" do
        consent_form =
          build(
            :consent_form,
            response: "refused",
            reason: "contains_gelatine",
            session:
          )
        expect(consent_form.form_steps).to include(:reason)
        expect(consent_form.form_steps).to include(:injection)
      end

      it "doesn't offer an injection alternative if the child has already received vaccine" do
        consent_form =
          build(
            :consent_form,
            response: "refused",
            reason: "already_vaccinated",
            session:
          )
        expect(consent_form.form_steps).to include(:reason)
        expect(consent_form.form_steps).not_to include(:injection)
      end
    end

    context "for an HPV campaign, when patient refuses consent" do
      it "does not offer an injection alternative" do
        # this assumes that the HPV campaign does not offer nasal spray vaccines, which is true in 2024
        consent_form =
          build(
            :consent_form,
            response: "refused",
            reason: "medical_reasons",
            session: build(:session, campaign: build(:campaign, :hpv))
          )
        expect(consent_form.form_steps).not_to include(:injection)
      end
    end

    it "does not ask for gp details when patient refuses consent" do
      consent_form = build(:consent_form, response: "refused")
      expect(consent_form.form_steps).not_to include(:gp)
    end

    it "asks for details when patient refuses for a few different reasons" do
      %w[
        medical_reasons
        will_be_vaccinated_elsewhere
        other
        already_vaccinated
      ].each do |reason|
        consent_form = build(:consent_form, response: "refused", reason:)
        expect(consent_form.form_steps).to include(:reason_notes)
      end
    end

    it "skips asking for details when patient refuses due to gelatine content or pesonal reason" do
      %w[contains_gelatine personal_choice].each do |reason|
        consent_form = build(:consent_form, response: "refused", reason:)
        expect(consent_form.form_steps).not_to include(:reason_notes)
      end
    end

    it "asks for gp details, address when patient gives consent" do
      consent_form = build(:consent_form, response: "given")
      expect(consent_form.form_steps).to include(:gp)
      expect(consent_form.form_steps).to include(:address)
    end
  end

  describe "#address_postcode=" do
    it "formats the postcode" do
      consent_form = build(:consent_form, address_postcode: "sw1a1aa")
      expect(consent_form.address_postcode).to eq("SW1A 1AA")
    end

    it "leaves nil as nil" do
      consent_form = build(:consent_form, address_postcode: nil)
      expect(consent_form.address_postcode).to eq(nil)
    end
  end

  describe "#each_health_answer" do
    context "linear health questions without branching" do
      let(:consent_form) do
        build(:consent_form, :with_health_answers_no_branching)
      end

      context "no answers recorded" do
        it "yields all the health answers in order" do
          expect { |b| consent_form.each_health_answer(&b) }.to(
            yield_successive_args(
              consent_form.health_answers[0],
              consent_form.health_answers[1],
              consent_form.health_answers[2]
            )
          )
        end
      end

      context "no answers requiring follow-up recorded" do
        it "yields all the health answers in order" do
          expect { |b| consent_form.each_health_answer(&b) }.to(
            yield_successive_args(
              consent_form.health_answers[0],
              consent_form.health_answers[1],
              consent_form.health_answers[2]
            )
          )
        end
      end

      context "answers require follow-up recorded" do
        it "yields all the health answers in order" do
          expect { |b| consent_form.each_health_answer(&b) }.to(
            yield_successive_args(
              consent_form.health_answers[0],
              consent_form.health_answers[1],
              consent_form.health_answers[2]
            )
          )
        end
      end
    end

    context "health answers with branching" do
      let(:consent_form) do
        build(:consent_form, :with_health_answers_asthma_branching)
      end

      context "no answers recorded" do
        it "yields all the health answers in order" do
          expect { |b| consent_form.each_health_answer(&b) }.to(
            yield_successive_args(
              consent_form.health_answers[0],
              consent_form.health_answers[1],
              consent_form.health_answers[2]
            )
          )
        end
      end

      context "no answers requiring follow-up " do
        it "yields the non follow-up health answers in order" do
          consent_form.health_answers[0].response = "no"
          consent_form.health_answers[2].response = "no"

          expect { |b| consent_form.each_health_answer(&b) }.to(
            yield_successive_args(
              consent_form.health_answers[0],
              consent_form.health_answers[2]
            )
          )
        end
      end

      context "answers require follow-up " do
        it "yields the normal and follow-up health answer in order" do
          consent_form.health_answers[0].response = "yse"
          consent_form.health_answers[1].response = "yes"
          consent_form.health_answers[2].response = "yes"

          expect { |b| consent_form.each_health_answer(&b) }.to(
            yield_successive_args(
              consent_form.health_answers[0],
              consent_form.health_answers[1],
              consent_form.health_answers[2]
            )
          )
        end
      end
    end

    context "accidental infinite loop" do
      it "raises an error" do
        consent_form = build :consent_form
        consent_form.health_answers[0].next_question = 0

        expect { |_b| consent_form.each_health_answer { nil } }.to(
          raise_error("Infinite loop detected")
        )
      end
    end
  end

  describe "#any_health_answers_truthy?" do
    let(:consent_form) do
      build(:consent_form, :with_health_answers_no_branching)
    end

    context "no responses are yes" do
      it "returns false" do
        expect(consent_form.any_health_answers_truthy?).to eq(false)
      end
    end

    context "some responses are yes" do
      it "returns true" do
        consent_form.health_answers[0].response = "yes"
        expect(consent_form.any_health_answers_truthy?).to eq(true)
      end
    end
  end

  describe "#gelatine_content_status_in_vaccines" do
    it "returns :maybe if the flu campaign offers both injection and nasal vaccines" do
      consent_form =
        build(
          :consent_form,
          session: build(:session, campaign: build(:campaign, :flu))
        )
      expect(consent_form.gelatine_content_status_in_vaccines).to eq(:maybe)
    end

    it "returns false if the flu campaign only offers injection vaccines" do
      consent_form =
        build(
          :consent_form,
          session: build(:session, campaign: build(:campaign, :flu_nasal_only))
        )
      expect(consent_form.gelatine_content_status_in_vaccines).to eq(true)
    end

    it "returns false for an HPV campaign" do
      consent_form =
        build(
          :consent_form,
          session: build(:session, campaign: build(:campaign, :hpv))
        )
      expect(consent_form.gelatine_content_status_in_vaccines).to eq(false)
    end
  end

  describe "scope unmatched" do
    let(:consent) { create(:consent) }
    let(:unmatched_consent_form) { create(:consent_form, consent: nil) }
    let(:matched_consent_form) { create(:consent_form, consent:) }

    it "returns unmatched consent forms" do
      expect(ConsentForm.unmatched).to include unmatched_consent_form
      expect(ConsentForm.unmatched).not_to include matched_consent_form
    end
  end

  describe "scope recorded" do
    let(:consent) { create(:consent) }
    let(:recorded_consent_form) { create(:consent_form, :recorded, consent:) }
    let(:draft_consent_form) { create(:consent_form, consent:) }

    it "returns unmatched consent forms" do
      expect(ConsentForm.recorded).to include recorded_consent_form
      expect(ConsentForm.recorded).not_to include draft_consent_form
    end
  end

  describe "#find_matching_patient" do
    subject { consent_form.find_matching_patient }

    let(:patients_in_session) { 1 }
    let!(:patients) do
      create_list(
        :patient,
        patients_in_session,
        sessions: [session],
        address_postcode: "SW1A 1AA"
      )
    end
    let!(:session) { create(:session) }
    let(:consent_form) { build(:consent_form, session:) }

    context "when there are no patients in the session" do
      let(:patients_in_session) { 0 }

      it { is_expected.to be_nil }
    end

    context "when there are unmatched patients in the session" do
      it { is_expected.to be_nil }
    end

    context "when there is one patient with matching first name and dob" do
      let(:consent_form) do
        build(
          :consent_form,
          session:,
          first_name: patients.first.first_name,
          date_of_birth: patients.first.date_of_birth
        )
      end

      it { is_expected.to be_nil }
    end

    context "when there are multiple patients with matching full_name and dob" do
      let!(:patients) do
        create_list(
          :patient,
          2,
          first_name: "John",
          last_name: "Doe",
          date_of_birth: 10.years.ago,
          sessions: [session]
        )
      end
      let(:consent_form) do
        build(
          :consent_form,
          session:,
          first_name: patients.first.first_name,
          last_name: patients.first.last_name,
          date_of_birth: patients.first.date_of_birth
        )
      end

      it { is_expected.to be_nil }
    end

    context "when there is one patient with matching full_name and dob" do
      let(:consent_form) do
        build(
          :consent_form,
          session:,
          first_name: patients.first.first_name,
          last_name: patients.first.last_name,
          date_of_birth: patients.first.date_of_birth
        )
      end

      it { is_expected.to eq patients.first }
    end

    context "when there is one patient with matching full_name and postcode" do
      let(:consent_form) do
        build(
          :consent_form,
          session:,
          first_name: patients.first.first_name,
          last_name: patients.first.last_name,
          address_postcode: patients.first.address_postcode
        )
      end

      it { is_expected.to eq patients.first }
    end

    context "when there is one patient with matching f_name, dob, postcode" do
      let(:consent_form) do
        build(
          :consent_form,
          session:,
          first_name: patients.first.first_name,
          date_of_birth: patients.first.date_of_birth,
          address_postcode: patients.first.address_postcode
        )
      end

      it { is_expected.to eq patients.first }
    end

    context "when there is one patient with matching l_name, dob, postcode" do
      let(:consent_form) do
        build(
          :consent_form,
          session:,
          last_name: patients.first.last_name,
          date_of_birth: patients.first.date_of_birth,
          address_postcode: patients.first.address_postcode
        )
      end

      it { is_expected.to eq patients.first }
    end
  end

  it "seeds the health questions when the parent gives consent" do
    consent_form = create(:consent_form, response: "refused")

    consent_form.update!(
      response: "given",
      address_line_1: "123 Fake St",
      address_town: "London",
      address_postcode: "SW1A 1AA",
      gp_response: "yes",
      gp_name: "Dr. Foo"
    )
    consent_form.reload

    expect(consent_form.health_answers).not_to be_empty
  end

  it "removes the health questions when the parent refuses consent" do
    consent_form =
      create(:consent_form, :with_health_answers_no_branching, response: nil)

    consent_form.update!(response: "refused", reason: "personal_choice")
    consent_form.reload

    expect(consent_form.health_answers).to be_empty
  end

  it "leaves the health questions when the parent gives consent" do
    consent_form =
      create(:consent_form, :with_health_answers_no_branching, response: nil)

    consent_form.update!(response: "given")
    consent_form.reload

    expect(consent_form.health_answers).not_to be_empty
  end

  describe "#summary_with_route" do
    it "summarises the consent form when consent is given" do
      consent_form = build(:consent_form, response: "given")
      expect(consent_form.summary_with_route).to eq("Consent given (online)")
    end

    it "summarises the consent form when consent is refused" do
      consent_form = build(:consent_form, response: "refused")
      expect(consent_form.summary_with_route).to eq("Consent refused (online)")
    end
  end

  it "resets unused fields" do
    consent_form =
      build(:consent_form, common_name: "John", use_common_name: true)
    consent_form.update!(use_common_name: false)
    expect(consent_form.common_name).to be_nil

    consent_form =
      build(
        :consent_form,
        response: "refused",
        reason: "contains_gelatine",
        reason_notes: "I'm vegan"
      )
    consent_form.update!(response: "given")
    expect(consent_form.reason).to be_nil
    expect(consent_form.reason_notes).to be_nil

    consent_form = build(:consent_form, gp_response: "yes", gp_name: "Dr. Foo")
    consent_form.update!(gp_response: "no")
    expect(consent_form.gp_name).to be_nil

    consent_form = build(:consent_form)
    consent_form.update!(response: "refused")
    expect(consent_form.gp_response).to be_nil
    expect(consent_form.address_line_1).to be_nil
    expect(consent_form.address_line_2).to be_nil
    expect(consent_form.address_town).to be_nil
    expect(consent_form.address_postcode).to be_nil
  end
end
