# frozen_string_literal: true

# == Schema Information
#
# Table name: pre_screenings
#
#  id                   :bigint           not null, primary key
#  notes                :text             default(""), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  patient_session_id   :bigint           not null
#  performed_by_user_id :bigint           not null
#  programme_id         :bigint           not null
#
# Indexes
#
#  index_pre_screenings_on_patient_session_id    (patient_session_id)
#  index_pre_screenings_on_performed_by_user_id  (performed_by_user_id)
#  index_pre_screenings_on_programme_id          (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#
describe PreScreening do
  subject(:pre_screening) { build(:pre_screening) }

  describe "scopes" do
    describe "#today" do
      subject { described_class.today }

      context "with an instance created today" do
        let(:pre_screening) { create(:pre_screening) }

        it { should include(pre_screening) }
      end

      context "with an instance created yesterday" do
        let(:pre_screening) { create(:pre_screening, created_at: 1.day.ago) }

        it { should_not include(pre_screening) }
      end
    end
  end

  describe "validations" do
    it { should_not validate_presence_of(:notes) }
    it { should validate_length_of(:notes).is_at_most(1000) }
  end
end
