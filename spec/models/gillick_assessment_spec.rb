# frozen_string_literal: true

# == Schema Information
#
# Table name: gillick_assessments
#
#  id                   :bigint           not null, primary key
#  knows_consequences   :boolean          not null
#  knows_delivery       :boolean          not null
#  knows_disease        :boolean          not null
#  knows_side_effects   :boolean          not null
#  knows_vaccination    :boolean          not null
#  notes                :text             default(""), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  patient_session_id   :bigint           not null
#  performed_by_user_id :bigint           not null
#
# Indexes
#
#  index_gillick_assessments_on_patient_session_id    (patient_session_id)
#  index_gillick_assessments_on_performed_by_user_id  (performed_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#
describe GillickAssessment do
  subject(:gillick_assessment) { build(:gillick_assessment) }

  describe "validations" do
    it { should allow_values(true, false).for(:knows_consequences) }
    it { should allow_values(true, false).for(:knows_delivery) }
    it { should allow_values(true, false).for(:knows_disease) }
    it { should allow_values(true, false).for(:knows_side_effects) }
    it { should allow_values(true, false).for(:knows_vaccination) }
  end

  describe "#gillick_competent?" do
    subject(:gillick_competent?) { gillick_assessment.gillick_competent? }

    context "when competent" do
      let(:gillick_assessment) { build(:gillick_assessment, :competent) }

      it { should be(true) }
    end

    context "when not competent" do
      let(:gillick_assessment) { build(:gillick_assessment, :not_competent) }

      it { should be(false) }
    end
  end
end
