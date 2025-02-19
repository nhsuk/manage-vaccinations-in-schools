# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_forms
#
#  id                                  :bigint           not null, primary key
#  address_line_1                      :string
#  address_line_2                      :string
#  address_postcode                    :string
#  address_town                        :string
#  archived_at                         :datetime
#  contact_injection                   :boolean
#  date_of_birth                       :date
#  education_setting                   :integer
#  family_name                         :text
#  given_name                          :text
#  health_answers                      :jsonb            not null
#  nhs_number                          :string
#  notes                               :text             default(""), not null
#  parent_contact_method_other_details :string
#  parent_contact_method_type          :string
#  parent_email                        :string
#  parent_full_name                    :string
#  parent_phone                        :string
#  parent_phone_receive_updates        :boolean          default(FALSE), not null
#  parent_relationship_other_name      :string
#  parent_relationship_type            :string
#  preferred_family_name               :string
#  preferred_given_name                :string
#  reason                              :integer
#  reason_notes                        :text
#  recorded_at                         :datetime
#  response                            :integer
#  school_confirmed                    :boolean
#  use_preferred_name                  :boolean
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  consent_id                          :bigint
#  location_id                         :bigint           not null
#  organisation_id                     :bigint           not null
#  programme_id                        :bigint           not null
#  school_id                           :bigint
#
# Indexes
#
#  index_consent_forms_on_consent_id       (consent_id)
#  index_consent_forms_on_location_id      (location_id)
#  index_consent_forms_on_nhs_number       (nhs_number)
#  index_consent_forms_on_organisation_id  (organisation_id)
#  index_consent_forms_on_programme_id     (programme_id)
#  index_consent_forms_on_school_id        (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (consent_id => consents.id)
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (school_id => locations.id)
#

describe ConsentForm do
  describe "validations" do
    subject(:consent_form) do
      build(
        :consent_form,
        health_answers:,
        parent_phone_receive_updates:,
        reason:,
        response:,
        session:,
        programme:,
        use_preferred_name:,
        wizard_step:
      )
    end

    let(:health_answers) { [] }
    let(:parent_phone_receive_updates) { false }
    let(:reason) { nil }
    let(:response) { nil }
    let(:programme) { build(:programme) }
    let(:session) { build(:session, programme:) }
    let(:use_preferred_name) { false }
    let(:wizard_step) { nil }

    it { should validate_presence_of(:given_name).on(:update) }
    it { should validate_presence_of(:family_name).on(:update) }
    it { should validate_presence_of(:date_of_birth).on(:update) }
    it { should_not validate_presence_of(:school_confirmed).on(:update) }
    it { should validate_presence_of(:response).on(:update) }

    it { should_not validate_presence_of(:parent_phone) }

    context "when users wants to receive text updates" do
      let(:parent_phone_receive_updates) { true }

      it { should validate_presence_of(:parent_phone) }
    end

    context "when wizard_step is :name" do
      let(:wizard_step) { :name }

      it { should validate_presence_of(:given_name).on(:update) }
      it { should validate_presence_of(:family_name).on(:update) }

      context "when use_preferred_name is true" do
        let(:use_preferred_name) { true }

        it { should validate_presence_of(:preferred_given_name).on(:update) }
        it { should validate_presence_of(:preferred_family_name).on(:update) }
      end
    end

    context "when wizard_step is :date_of_birth" do
      let(:wizard_step) { :date_of_birth }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:given_name).on(:update) }
      end

      it { should validate_presence_of(:date_of_birth).on(:update) }

      context "with a date of birth that's too young" do
        before { travel_to(Date.new(2022, 1, 1)) }

        it "has the correct error message" do
          consent_form.date_of_birth = 2.years.ago.to_date
          consent_form.valid?(:update)
          # the date formatting below relies on the
          # custom interpolation from I18n::CustomInterpolation
          expect(consent_form.errors[:date_of_birth]).to contain_exactly(
            "The child cannot be younger than 3. Enter a date before 1 January 2019."
          )
        end
      end

      context "with a date of birth that's too old" do
        before { travel_to(Date.new(2022, 1, 1)) }

        it "has the correct error message" do
          consent_form.date_of_birth = 23.years.ago.to_date
          consent_form.valid?(:update)
          # the date formatting below relies on the
          # custom interpolation from I18n::CustomInterpolation
          expect(consent_form.errors[:date_of_birth]).to contain_exactly(
            "The child cannot be older than 22. Enter a date after 1 January 2000."
          )
        end
      end
    end

    context "when wizard_step is :parent" do
      let(:wizard_step) { :parent }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:given_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
      end
    end

    context "when wizard_step is :consent" do
      let(:wizard_step) { :consent }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:given_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
      end

      it { should validate_presence_of(:response).on(:update) }
    end

    context "when wizard_step is :reason" do
      let(:response) { "refused" }
      let(:wizard_step) { :reason }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:given_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
      end

      it { should validate_presence_of(:reason).on(:update) }
    end

    context "when wizard_step is :reason_notes" do
      let(:response) { "refused" }
      let(:reason) { "medical_reasons" }
      let(:wizard_step) { :reason_notes }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:given_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
      end

      it { should validate_presence_of(:reason_notes).on(:update) }
    end

    context "when wizard_step is :injection" do
      # currently injection alternative only offered during flu programme
      let(:programme) { build(:programme, :flu) }

      let(:response) { "refused" }
      let(:reason) { "contains_gelatine" }
      let(:wizard_step) { :injection }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:given_name).on(:update) }
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

    context "when wizard_step is :address" do
      let(:response) { "given" }
      let(:wizard_step) { :address }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:given_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
      end

      it { should validate_presence_of(:address_line_1).on(:update) }
      it { should validate_presence_of(:address_town).on(:update) }
      it { should validate_presence_of(:address_postcode).on(:update) }

      it do
        expect(consent_form).not_to allow_value("invalid").for(
          :address_postcode
        ).on(:update)
      end
    end

    context "when wizard_step is :health_question" do
      let(:response) { "given" }
      let(:wizard_step) { :health_question }
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
        it { should validate_presence_of(:given_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
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
        expect(consent_form).not_to be_valid
      end

      it "checks follow-up questions if necessary" do
        health_answers[0].response = "yes"
        health_answers[0].notes = "for the tests"
        health_answers[2].response = "no"

        consent_form.save # rubocop:disable Rails/SaveBang
        expect(consent_form).not_to be_valid
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

  it { should normalize(:given_name).from(" Joanna ").to("Joanna") }
  it { should normalize(:family_name).from(" Smith ").to("Smith") }
  it { should normalize(:address_postcode).from(" SW111AA ").to("SW11 1AA") }

  it_behaves_like "a model with a normalised email address", :parent_email
  it_behaves_like "a model with a normalised phone number", :parent_phone

  describe "#full_name" do
    it "returns the full name as a string" do
      consent_form =
        build(:consent_form, given_name: "John", family_name: "Doe")
      expect(consent_form.full_name).to eq("DOE, John")
    end
  end

  describe "#wizard_steps" do
    it "does not ask for reason for refusal when patient gives consent" do
      consent_form = build(:consent_form, response: "given")
      expect(consent_form.wizard_steps).not_to include(:reason)
      expect(consent_form.wizard_steps).not_to include(:injection)
    end

    context "for a flu programme, when patient refuses consent" do
      let(:programme) { build(:programme, :flu) }

      it "offers an injection alternative if the child hasn't received vaccine elsewhere" do
        consent_form =
          build(
            :consent_form,
            response: "refused",
            reason: "contains_gelatine",
            programme:
          )
        expect(consent_form.wizard_steps).to include(:reason)
        expect(consent_form.wizard_steps).to include(:injection)
      end

      it "doesn't offer an injection alternative if the child has already received vaccine" do
        consent_form =
          build(
            :consent_form,
            response: "refused",
            reason: "already_vaccinated",
            programme:
          )
        expect(consent_form.wizard_steps).to include(:reason)
        expect(consent_form.wizard_steps).not_to include(:injection)
      end
    end

    context "for an HPV programme, when patient refuses consent" do
      it "does not offer an injection alternative" do
        # this assumes that the HPV programme does not offer nasal spray vaccines, which is true in 2024
        consent_form =
          build(
            :consent_form,
            programme: build(:programme, :hpv),
            response: "refused",
            reason: "medical_reasons"
          )
        expect(consent_form.wizard_steps).not_to include(:injection)
      end
    end

    it "asks for details when patient refuses for a few different reasons" do
      session = create(:session)

      %w[
        medical_reasons
        will_be_vaccinated_elsewhere
        other
        already_vaccinated
      ].each do |reason|
        consent_form =
          build(:consent_form, response: "refused", reason:, session:)
        expect(consent_form.wizard_steps).to include(:reason_notes)
      end
    end

    it "skips asking for details when patient refuses due to gelatine content or pesonal reason" do
      session = create(:session)

      %w[contains_gelatine personal_choice].each do |reason|
        consent_form =
          build(:consent_form, response: "refused", reason:, session:)
        expect(consent_form.wizard_steps).not_to include(:reason_notes)
      end
    end
  end

  describe "#address_postcode=" do
    it "formats the postcode" do
      consent_form = build(:consent_form, address_postcode: "sw1a1aa")
      expect(consent_form.address_postcode).to eq("SW1A 1AA")
    end

    it "leaves nil as nil" do
      consent_form = build(:consent_form, address_postcode: nil)
      expect(consent_form.address_postcode).to be_nil
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
          consent_form.health_answers[0].response = "no"
          consent_form.health_answers[2].response = "no"

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
          consent_form.health_answers[0].response = "yes"
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

      context "no answers requiring follow-up" do
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

      context "answers require follow-up" do
        it "yields the normal and follow-up health answer in order" do
          consent_form.health_answers[0].response = "yes"
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
        expect(consent_form.any_health_answers_truthy?).to be(false)
      end
    end

    context "some responses are yes" do
      it "returns true" do
        consent_form.health_answers[0].response = "yes"
        expect(consent_form.any_health_answers_truthy?).to be(true)
      end
    end
  end

  describe "#gelatine_content_status_in_vaccines" do
    it "returns :maybe if the flu programme offers both injection and nasal vaccines" do
      consent_form = build(:consent_form, programme: build(:programme, :flu))
      expect(consent_form.gelatine_content_status_in_vaccines).to eq(:maybe)
    end

    it "returns false if the flu programme only offers injection vaccines" do
      consent_form =
        build(:consent_form, programme: build(:programme, :flu_nasal_only))
      expect(consent_form.gelatine_content_status_in_vaccines).to be(true)
    end

    it "returns false for an HPV programme" do
      consent_form = build(:consent_form, programme: build(:programme, :hpv))
      expect(consent_form.gelatine_content_status_in_vaccines).to be(false)
    end
  end

  describe "scope unmatched" do
    let(:programme) { create(:programme) }
    let(:session) { create(:session, programme:) }
    let(:consent) { create(:consent, programme:) }
    let(:unmatched_consent_form) do
      create(:consent_form, consent: nil, programme:, session:)
    end
    let(:matched_consent_form) do
      create(:consent_form, consent:, programme:, session:)
    end

    it "returns unmatched consent forms" do
      expect(described_class.unmatched).to include unmatched_consent_form
      expect(described_class.unmatched).not_to include matched_consent_form
    end
  end

  describe "scope recorded" do
    let(:programme) { create(:programme) }
    let(:session) { create(:session, programme:) }
    let(:consent) { create(:consent, programme:) }
    let(:recorded_consent_form) do
      create(:consent_form, :recorded, programme:, consent:, session:)
    end
    let(:draft_consent_form) do
      create(:consent_form, programme:, consent:, session:)
    end

    it "returns unmatched consent forms" do
      expect(described_class.recorded).to include recorded_consent_form
      expect(described_class.recorded).not_to include draft_consent_form
    end
  end

  it "seeds the health questions when the parent gives consent" do
    consent_form =
      create(
        :consent_form,
        session: create(:session, programme: create(:programme, :hpv)),
        response: "refused"
      )

    consent_form.update!(
      response: "given",
      address_line_1: "123 Fake St",
      address_town: "London",
      address_postcode: "SW1A 1AA"
    )
    consent_form.reload

    expect(consent_form.health_answers).not_to be_empty
  end

  it "removes the health questions when the parent refuses consent for flu" do
    consent_form =
      create(
        :consent_form,
        :with_health_answers_no_branching,
        session: create(:session, programme: create(:programme, :flu)),
        response: nil
      )

    consent_form.update!(
      response: "refused",
      reason: "personal_choice",
      contact_injection: false
    )
    consent_form.reload

    expect(consent_form.health_answers).to be_empty
  end

  it "removes the health questions when the parent refuses consent for HPV" do
    consent_form =
      create(
        :consent_form,
        :with_health_answers_no_branching,
        session: create(:session, programme: create(:programme, :hpv)),
        response: nil
      )

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

  describe "#match_with_patient!" do
    subject(:match_with_patient!) do
      consent_form.match_with_patient!(patient, current_user:)
    end

    let(:programme) { create(:programme) }
    let(:organisation) { create(:organisation, programmes: [programme]) }

    let(:school) { create(:school) }
    let(:location) { school }
    let(:session) { create(:session, organisation:, programme:, location:) }
    let(:patient) { create(:patient, school:, session:) }
    let(:current_user) { create(:user) }

    let(:notify_log_entry) do
      create(:notify_log_entry, :email, consent_form:, patient: nil)
    end

    context "when consent form confirms the school" do
      let(:consent_form) do
        create(:consent_form, organisation:, session:, school_confirmed: true)
      end

      it "creates a consent" do
        expect { match_with_patient! }.to change(Consent, :count).by(1)
      end

      it "doesn't change the patient's school" do
        expect { match_with_patient! }.not_to change(patient, :school)
      end

      it "assigns any notify log entries" do
        expect { match_with_patient! }.to change {
          notify_log_entry.reload.patient
        }.from(nil).to(patient)
      end
    end

    context "when the patient goes to a different school" do
      let(:consent_form) do
        create(
          :consent_form,
          organisation:,
          session:,
          school_confirmed: false,
          school: new_school
        )
      end

      let(:new_school) { create(:school) }

      it "creates a consent" do
        expect { match_with_patient! }.to change(Consent, :count).by(1)
      end

      it "doesn't change the patient's school" do
        expect { match_with_patient! }.not_to change(patient, :school)
      end

      it "doesn't change the patient's home educated status" do
        expect { match_with_patient! }.not_to change(patient, :home_educated)
      end

      it "creates a school move" do
        expect { match_with_patient! }.to change(
          patient.school_moves,
          :count
        ).by(1)

        school_move = patient.school_moves.first
        expect(school_move.school_id).to eq(new_school.id)
      end
    end

    context "when the patient is home educated" do
      let(:consent_form) do
        create(
          :consent_form,
          organisation:,
          session:,
          school_confirmed: nil,
          education_setting: "home"
        )
      end

      let(:new_location) { create(:generic_clinic, organisation:) }

      it "creates a consent" do
        expect { match_with_patient! }.to change(Consent, :count).by(1)
      end

      it "doesn't change the patient's school" do
        expect { match_with_patient! }.not_to change(patient, :school)
      end

      it "changes the patient's home educated status" do
        expect { match_with_patient! }.not_to change(patient, :home_educated)
      end

      it "creates a school move" do
        expect { match_with_patient! }.to change(
          patient.school_moves,
          :count
        ).by(1)

        school_move = patient.school_moves.first
        expect(school_move.school).to be_nil
        expect(school_move.home_educated).to be(true)
      end
    end
  end

  it "resets unused fields" do
    programme = create(:programme)

    session = create(:session, programme:)

    consent_form =
      build(
        :consent_form,
        programme:,
        preferred_given_name: "John",
        use_preferred_name: true,
        session:
      )
    consent_form.update!(use_preferred_name: false)
    expect(consent_form.preferred_given_name).to be_nil

    consent_form =
      build(
        :consent_form,
        programme:,
        response: "refused",
        reason: "contains_gelatine",
        reason_notes: "I'm vegan",
        session:
      )
    consent_form.update!(response: "given")
    expect(consent_form.reason).to be_nil
    expect(consent_form.reason_notes).to be_nil

    consent_form = build(:consent_form, programme:, session:)
    consent_form.update!(response: "refused")
    expect(consent_form.address_line_1).to be_nil
    expect(consent_form.address_line_2).to be_nil
    expect(consent_form.address_town).to be_nil
    expect(consent_form.address_postcode).to be_nil
  end
end
