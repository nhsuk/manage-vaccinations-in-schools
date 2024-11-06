# frozen_string_literal: true

# == Schema Information
#
# Table name: consents
#
#  id                       :bigint           not null, primary key
#  health_answers           :jsonb
#  reason_for_refusal       :integer
#  reason_for_refusal_notes :text
#  recorded_at              :datetime
#  response                 :integer
#  route                    :integer
#  withdrawn_at             :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  organisation_id          :bigint           not null
#  parent_id                :bigint
#  patient_id               :bigint           not null
#  programme_id             :bigint           not null
#  recorded_by_user_id      :bigint
#
# Indexes
#
#  index_consents_on_organisation_id      (organisation_id)
#  index_consents_on_parent_id            (parent_id)
#  index_consents_on_patient_id           (patient_id)
#  index_consents_on_programme_id         (programme_id)
#  index_consents_on_recorded_by_user_id  (recorded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (parent_id => parents.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (recorded_by_user_id => users.id)
#

describe Consent do
  describe "when consent given by parent or guardian, all health questions are no" do
    it "does not require triage" do
      response = build(:consent, :given)

      expect(response).not_to be_triage_needed
    end
  end

  describe "when consent given by parent or guardian, but some info provided in the health questions" do
    it "does require triage" do
      health_answers = [
        HealthAnswer.new(
          question:
            "Does the child have a disease or treatment that severely affects their immune system?",
          response: "yes"
        )
      ]
      response = build(:consent, :given, health_answers:)

      expect(response).to be_triage_needed
    end

    it "returns notes need triage" do
      response = build(:consent, :given, :health_question_notes)

      expect(response.reasons_triage_needed).to eq(
        ["Health questions need triage"]
      )
    end
  end

  describe "#contactable?" do
    subject(:contactable?) { consent.contactable? }

    context "without a parent" do
      let(:consent) { build(:consent) }

      it { should be(false) }
    end

    context "with a non-contactable parent" do
      let(:consent) do
        build(:consent, parent: build(:parent, :non_contactable))
      end

      it { should be(false) }
    end

    context "with a contactable parent" do
      let(:consent) { build(:consent, parent: build(:parent)) }

      it { should be(true) }
    end
  end

  describe "#from_consent_form!" do
    describe "the created consent object" do
      subject(:consent) do
        described_class.from_consent_form!(consent_form, patient:)
      end

      let(:consent_form) { create(:consent_form, :recorded) }
      let(:patient) { create(:patient) }

      it "copies over attributes from consent_form" do
        expect(consent).to(
          have_attributes(
            programme: consent_form.programme,
            patient:,
            consent_form:,
            reason_for_refusal: consent_form.reason,
            reason_for_refusal_notes: consent_form.reason_notes,
            response: consent_form.response,
            route: "website"
          )
        )
      end

      it "creates a parent" do
        expect(consent.parent).to be_recorded
        expect(consent.parent).to have_attributes(
          full_name: consent_form.parent_full_name,
          email: consent_form.parent_email,
          phone: Phonelib.parse(consent_form.parent_phone).national,
          phone_receive_updates: consent_form.parent_phone_receive_updates
        )
      end

      it "copies health answers from consent_form" do
        expect(consent.health_answers.to_json).to eq(
          consent_form.health_answers.to_json
        )
      end

      context "with an existing parent" do
        let(:parent) do
          create(:parent, full_name: consent_form.parent_full_name)
        end

        before { create(:parent_relationship, patient:, parent:) }

        it "re-uses the same parent" do
          expect(consent.parent).to eq(parent)
          expect(consent.parent).to be_recorded
          expect(consent.parent).to have_attributes(
            full_name: consent_form.parent_full_name,
            email: consent_form.parent_email,
            phone: Phonelib.parse(consent_form.parent_phone).national,
            phone_receive_updates: consent_form.parent_phone_receive_updates
          )
        end
      end
    end
  end

  describe "#recorded scope" do
    let(:patient) { create(:patient) }
    let(:programme) { create(:programme) }

    it "returns only consents that have been recorded" do
      consent =
        create(:consent, patient:, recorded_at: Time.zone.now, programme:)
      create(:consent, :draft, patient:, programme:)

      expect(patient.consents.unscope(where: :recorded).recorded).to eq(
        [consent]
      )
    end
  end

  describe "#recorded?" do
    it "returns true if recorded_at is set" do
      consent = build(:consent, recorded_at: Time.zone.now)

      expect(consent).to be_recorded
    end

    it "returns false if recorded_at is nil" do
      consent = build(:consent, recorded_at: nil)

      expect(consent).not_to be_recorded
    end
  end

  it "resets unused fields after a consent refusal" do
    consent =
      build(
        :consent,
        programme: create(:programme, :hpv),
        health_answers: [],
        response: "refused",
        reason_for_refusal: "contains_gelatine",
        reason_for_refusal_notes: "I'm vegan"
      )
    expect(consent.health_answers).to be_empty

    consent.update!(response: "given")

    expect(consent.reason_for_refusal).to be_nil
    expect(consent.reason_for_refusal_notes).to be_nil

    expect(consent.health_answers).not_to be_empty
    expect(consent.health_answers.count).to eq(
      consent.programme.vaccines.first.health_questions.count
    )
    expect(consent.health_answers.map(&:response)).to all(be_nil)
  end

  it "resets unused fields after a consent being given" do
    consent = build(:consent, :given)
    expect(consent.health_answers).not_to be_empty

    consent.update!(response: "refused")

    expect(consent.health_answers).to be_empty
  end

  it "resets health answer notes if a 'yes' changes to a 'no'" do
    consent = build(:consent, :given, :health_question_notes)
    expect(consent.health_answers.first.response).to eq("yes")
    expect(consent.health_answers.first.notes).to be_present

    param =
      ActionController::Parameters.new(
        { "notes" => "Some notes", "response" => "no" }
      )
    param.permit!

    consent.health_answers.first.assign_attributes(param)
    consent.save!
    consent.reload

    expect(consent.health_answers.first.response).to eq("no")
    expect(consent.health_answers.first.notes).to be_nil
  end
end
