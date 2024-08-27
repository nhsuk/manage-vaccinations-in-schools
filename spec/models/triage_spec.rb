# frozen_string_literal: true

# == Schema Information
#
# Table name: triage
#
#  id                   :bigint           not null, primary key
#  notes                :text             default(""), not null
#  status               :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  patient_session_id   :bigint           not null
#  performed_by_user_id :bigint           not null
#
# Indexes
#
#  index_triage_on_patient_session_id    (patient_session_id)
#  index_triage_on_performed_by_user_id  (performed_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#

describe Triage, type: :model do
  subject(:triage) { build(:triage) }

  describe "validations" do
    it { should_not validate_presence_of(:notes) }
    it { should validate_length_of(:notes).is_at_most(1000) }
  end
end
