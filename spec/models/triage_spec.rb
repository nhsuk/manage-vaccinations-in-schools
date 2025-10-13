# frozen_string_literal: true

# == Schema Information
#
# Table name: triages
#
#  id                      :bigint           not null, primary key
#  academic_year           :integer          not null
#  delay_vaccination_until :date
#  invalidated_at          :datetime
#  notes                   :text             default(""), not null
#  status                  :integer          not null
#  vaccine_method          :integer
#  without_gelatine        :boolean
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  patient_id              :bigint           not null
#  performed_by_user_id    :bigint           not null
#  programme_id            :bigint           not null
#  team_id                 :bigint           not null
#
# Indexes
#
#  index_triages_on_academic_year         (academic_year)
#  index_triages_on_patient_id            (patient_id)
#  index_triages_on_performed_by_user_id  (performed_by_user_id)
#  index_triages_on_programme_id          (programme_id)
#  index_triages_on_team_id               (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (team_id => teams.id)
#

describe Triage do
  subject { build(:triage) }

  describe "associations" do
    it { should belong_to(:patient) }
    it { should belong_to(:programme) }
    it { should belong_to(:team) }
    it { should belong_to(:performed_by) }
  end

  describe "scopes" do
    describe "#delay_vaccination_until_in_past" do
      subject(:scope) { described_class.delay_vaccination_until_in_past }

      it { should be_empty }

      context "with a triage safe to vaccinate" do
        before { create(:triage, :safe_to_vaccinate) }

        it { should be_empty }
      end

      context "with a triage delayed until tomorrow" do
        before do
          create(
            :triage,
            :delay_vaccination,
            delay_vaccination_until: Date.tomorrow
          )
        end

        it { should be_empty }
      end

      context "with a triage delayed until today" do
        before do
          create(
            :triage,
            :delay_vaccination,
            delay_vaccination_until: Date.current
          )
        end

        it { should be_empty }
      end

      context "with a triage delayed until yesterday" do
        let!(:triage) do
          create(
            :triage,
            :delay_vaccination,
            delay_vaccination_until: Date.yesterday
          )
        end

        it { should include(triage) }
      end
    end

    describe "#should_be_invalidated" do
      subject(:scope) { described_class.should_be_invalidated }

      it { should be_empty }

      context "with a triage safe to vaccinate" do
        before { create(:triage, :safe_to_vaccinate) }

        it { should be_empty }
      end

      context "with a triage delayed until tomorrow" do
        before do
          create(
            :triage,
            :delay_vaccination,
            delay_vaccination_until: Date.tomorrow
          )
        end

        it { should be_empty }
      end

      context "with a triage delayed until today" do
        before do
          create(
            :triage,
            :delay_vaccination,
            delay_vaccination_until: Date.current
          )
        end

        it { should be_empty }
      end

      context "with a triage delayed until yesterday" do
        let!(:triage) do
          create(
            :triage,
            :delay_vaccination,
            delay_vaccination_until: Date.yesterday
          )
        end

        it { should include(triage) }
      end

      context "with a triage delayed until yesterday but already invalidated" do
        before do
          create(
            :triage,
            :delay_vaccination,
            :invalidated,
            delay_vaccination_until: Date.yesterday
          )
        end

        it { should be_empty }
      end
    end
  end

  describe "validations" do
    context "when safe to vaccinate" do
      subject(:triage) { build(:triage, :safe_to_vaccinate) }

      it do
        expect(triage).to validate_inclusion_of(:vaccine_method).in_array(
          %w[injection nasal]
        )
      end

      it { should validate_absence_of(:delay_vaccination_until) }
    end

    context "when do not vaccinate" do
      subject(:triage) { build(:triage, :do_not_vaccinate) }

      it { should validate_absence_of(:delay_vaccination_until) }
    end

    context "when keep in triage" do
      subject(:triage) { build(:triage, :keep_in_triage) }

      it { should validate_absence_of(:delay_vaccination_until) }
    end

    context "when delay vaccination" do
      subject(:triage) { build(:triage, :delay_vaccination) }

      it { should_not validate_absence_of(:delay_vaccination_until) }
    end
  end
end
