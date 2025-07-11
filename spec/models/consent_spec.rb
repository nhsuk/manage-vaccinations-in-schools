# frozen_string_literal: true

# == Schema Information
#
# Table name: consents
#
#  id                  :bigint           not null, primary key
#  health_answers      :jsonb            not null
#  invalidated_at      :datetime
#  notes               :text             default(""), not null
#  notify_parents      :boolean
#  reason_for_refusal  :integer
#  response            :integer          not null
#  route               :integer          not null
#  submitted_at        :datetime         not null
#  vaccine_methods     :integer          default([]), not null, is an Array
#  withdrawn_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  organisation_id     :bigint           not null
#  parent_id           :bigint
#  patient_id          :bigint           not null
#  programme_id        :bigint           not null
#  recorded_by_user_id :bigint
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
  describe "validations" do
    it { should validate_length_of(:notes).is_at_most(1000) }

    context "when response is given" do
      subject { build(:consent, :given) }

      it { should validate_presence_of(:vaccine_methods) }
    end

    context "when response is refused" do
      subject { build(:consent, :refused) }

      it { should_not validate_presence_of(:vaccine_methods) }
    end
  end

  describe "#verbal_routes" do
    subject(:verbal_routes) { described_class.verbal_routes }

    it "does not include online or self-consent do" do
      expect(verbal_routes.keys).to match_array(%w[phone paper in_person])
    end
  end

  describe "when consent given by parent or guardian, all health questions are no" do
    it "does not require triage" do
      response = build(:consent, :given)

      expect(response).not_to be_requires_triage
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

      expect(response).to be_requires_triage
    end
  end

  describe "#responded_at" do
    subject(:responded_at) { consent.responded_at }

    let(:consent) do
      build(:consent, submitted_at: Time.zone.local(2024, 12, 20, 12))
    end

    it { should eq(Time.zone.local(2024, 12, 20, 12)) }
  end

  describe "#from_consent_form!" do
    context "with on programme" do
      subject(:consent) do
        described_class.from_consent_form!(
          consent_form,
          patient:,
          current_user:
        ).first
      end

      let(:consent_form) { create(:consent_form, :recorded, reason_notes: nil) }
      let(:patient) { create(:patient) }
      let(:current_user) { create(:user) }

      it "sets who matched the consent" do
        expect(consent.recorded_by).to eq(current_user)
      end

      it "copies over attributes from consent form" do
        expect(consent).to(
          have_attributes(
            programme: consent_form.programmes.first,
            patient:,
            consent_form:,
            reason_for_refusal: consent_form.reason,
            notes: "",
            response: "given",
            route: "website"
          )
        )
      end

      it "creates a parent" do
        expect(consent.parent).to have_attributes(
          contact_method_other_details:
            consent_form.parent_contact_method_other_details,
          contact_method_type: consent_form.parent_contact_method_type,
          email: consent_form.parent_email,
          full_name: consent_form.parent_full_name,
          phone: consent_form.parent_phone,
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
          expect(consent.parent).to have_attributes(
            full_name: consent_form.parent_full_name,
            email: consent_form.parent_email,
            phone: Phonelib.parse(consent_form.parent_phone).national,
            phone_receive_updates: consent_form.parent_phone_receive_updates
          )
        end
      end

      context "when consenting to nasal spray" do
        before do
          consent_form.consent_form_programmes.first.update!(
            vaccine_methods: %w[nasal]
          )
        end

        it "stores this preference on the consent" do
          expect(consent.vaccine_methods).to contain_exactly("nasal")
        end
      end
    end

    context "with multiple programmes" do
      subject(:consents) do
        described_class.from_consent_form!(
          consent_form,
          patient:,
          current_user:
        )
      end

      let(:programmes) do
        [create(:programme, :menacwy), create(:programme, :td_ipv)]
      end
      let(:patient) { create(:patient) }
      let(:current_user) { create(:user) }
      let(:organisation) { create(:organisation, programmes:) }
      let(:session) { create(:session, organisation:, programmes:) }
      let(:consent_form) do
        create(
          :consent_form,
          :recorded,
          session:,
          reason: :personal_choice,
          reason_notes: "Personal reasons."
        )
      end

      before do
        consent_form.consent_form_programmes.first.update!(
          response: "given",
          vaccine_methods: %w[injection]
        )
        consent_form.consent_form_programmes.second.update!(
          response: "refused",
          vaccine_methods: []
        )
      end

      it "creates a consent per programme" do
        expect(consents.map(&:programme)).to eq(programmes)
      end

      it "creates consent given for MenACWY" do
        expect(consents.first).to have_attributes(
          programme: programmes.first,
          patient:,
          consent_form:,
          reason_for_refusal: nil,
          notes: "",
          response: "given",
          route: "website"
        )
      end

      it "creates consent refused for Td/IPV" do
        expect(consents.second).to have_attributes(
          programme: programmes.second,
          patient:,
          consent_form:,
          reason_for_refusal: "personal_choice",
          notes: "Personal reasons.",
          response: "refused",
          route: "website"
        )
      end
    end
  end

  it "resets health answer notes if a 'yes' changes to a 'no'" do
    consent =
      build(:consent, :given, :health_question_notes, parent: create(:parent))
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
