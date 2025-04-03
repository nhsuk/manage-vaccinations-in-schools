# frozen_string_literal: true

# == Schema Information
#
# Table name: pre_screenings
#
#  id                    :bigint           not null, primary key
#  feeling_well          :boolean          not null
#  knows_vaccination     :boolean          not null
#  no_allergies          :boolean          not null
#  not_already_had       :boolean          not null
#  not_pregnant          :boolean          not null
#  not_taking_medication :boolean          not null
#  notes                 :text             default(""), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  patient_session_id    :bigint           not null
#  performed_by_user_id  :bigint           not null
#  programme_id          :bigint           not null
#  session_date_id       :bigint           not null
#
# Indexes
#
#  index_pre_screenings_on_patient_session_id    (patient_session_id)
#  index_pre_screenings_on_performed_by_user_id  (performed_by_user_id)
#  index_pre_screenings_on_programme_id          (programme_id)
#  index_pre_screenings_on_session_date_id       (session_date_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (session_date_id => session_dates.id)
#
describe PreScreening do
  subject(:pre_screening) { build(:pre_screening) }

  describe "validations" do
    it { should allow_values(true, false).for(:knows_vaccination) }
    it { should allow_values(true, false).for(:not_already_had) }
    it { should allow_values(true, false).for(:feeling_well) }
    it { should allow_values(true, false).for(:no_allergies) }
    it { should_not validate_presence_of(:notes) }
  end

  describe "#allows_vaccination?" do
    subject(:allows_vaccination?) { pre_screening.allows_vaccination? }

    context "when allows vaccination" do
      let(:pre_screening) { create(:pre_screening, :allows_vaccination) }

      it { should be(true) }

      context "and the patient is feeling unwell" do
        let(:pre_screening) do
          create(:pre_screening, :allows_vaccination, feeling_well: false)
        end

        it { should be(true) }
      end
    end

    context "when prevents vaccination" do
      let(:pre_screening) { create(:pre_screening, :prevents_vaccination) }

      it { should be(false) }
    end
  end
end
