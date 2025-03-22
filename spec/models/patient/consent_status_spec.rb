# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_consent_statuses
#
#  id                               :bigint           not null, primary key
#  health_answers_require_follow_up :boolean          default(FALSE), not null
#  status                           :integer          default("no_response"), not null
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  patient_id                       :bigint           not null
#  programme_id                     :bigint           not null
#
# Indexes
#
#  index_patient_consent_statuses_on_patient_id                   (patient_id)
#  index_patient_consent_statuses_on_patient_id_and_programme_id  (patient_id,programme_id) UNIQUE
#  index_patient_consent_statuses_on_programme_id                 (programme_id)
#  index_patient_consent_statuses_on_status                       (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
describe Patient::ConsentStatus do
  subject(:patient_consent_status) do
    build(:patient_consent_status, patient:, programme:)
  end

  let(:patient) { create(:patient) }
  let(:programme) { create(:programme) }

  it { should belong_to(:patient) }
  it { should belong_to(:programme) }

  it do
    expect(patient_consent_status).to define_enum_for(:status).with_values(
      %i[no_response given refused conflicts]
    )
  end

  describe "#status" do
    subject do
      patient_consent_status.refresh!
      patient_consent_status.status
    end

    context "with no consent" do
      it { should eq("no_response") }
    end

    context "with an invalidated consent" do
      before { create(:consent, :invalidated, patient:, programme:) }

      it { should eq("no_response") }
    end

    context "with a not provided consent" do
      before { create(:consent, :not_provided, patient:, programme:) }

      it { should eq("no_response") }
    end

    context "with both an invalidated and not provided consent" do
      before do
        create(:consent, :invalidated, patient:, programme:)
        create(:consent, :not_provided, patient:, programme:)
      end

      it { should eq("no_response") }
    end

    context "with a refused consent" do
      before { create(:consent, :refused, patient:, programme:) }

      it { should eq("refused") }
    end

    context "with a given consent" do
      before { create(:consent, :given, patient:, programme:) }

      it { should eq("given") }
    end

    context "with conflicting consent" do
      before do
        create(:consent, :given, patient:, programme:)
        create(
          :consent,
          :refused,
          patient:,
          programme:,
          parent: create(:parent)
        )
      end

      it { should eq("conflicts") }
    end

    context "with an invalidated refused and given consent" do
      before do
        create(:consent, :refused, :invalidated, patient:, programme:)
        create(:consent, :given, patient:, programme:)
      end

      it { should eq("given") }
    end

    context "with self-consent" do
      before { create(:consent, :self_consent, :given, patient:, programme:) }

      it { should eq("given") }

      context "and refused parental consent" do
        before { create(:consent, :refused, patient:, programme:) }

        it { should eq("given") }
      end

      context "and conflicting parental consent" do
        before do
          create(:consent, :refused, patient:, programme:)
          create(
            :consent,
            :given,
            patient:,
            programme:,
            parent: create(:parent)
          )
        end

        it { should eq("given") }
      end
    end
  end

  describe "#health_answers_require_follow_up" do
    subject do
      patient_consent_status.refresh!
      patient_consent_status.health_answers_require_follow_up
    end

    context "with no consent" do
      it { should be(false) }
    end

    context "with an invalidated consent with health answers" do
      before do
        create(
          :consent,
          :invalidated,
          :health_question_notes,
          patient:,
          programme:
        )
      end

      it { should be(false) }
    end

    context "with a consent with health answers" do
      before { create(:consent, :health_question_notes, patient:, programme:) }

      it { should be(true) }
    end
  end
end
