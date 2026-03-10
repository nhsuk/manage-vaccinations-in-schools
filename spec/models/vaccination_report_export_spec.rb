# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccination_report_exports
#
#  id             :uuid             not null, primary key
#  academic_year  :integer          not null
#  date_from      :date
#  date_to        :date
#  expired_at     :datetime
#  file_format    :string           not null
#  programme_type :string           not null
#  status         :string           default("pending"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  team_id        :bigint           not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_vaccination_report_exports_on_created_at  (created_at)
#  index_vaccination_report_exports_on_status      (status)
#  index_vaccination_report_exports_on_team_id     (team_id)
#  index_vaccination_report_exports_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (user_id => users.id)
#
describe VaccinationReportExport do
  subject(:export) do
    build(
      :vaccination_report_export,
      team:,
      user:,
      programme_type: "flu",
      academic_year: 2024,
      file_format: "mavis"
    )
  end

  let(:team) { create(:team, :with_one_nurse, programmes: [Programme.flu]) }
  let(:user) { team.users.first }

  it { is_expected.to be_valid }

  describe "validations" do
    it { is_expected.to validate_presence_of(:programme_type) }
    it { is_expected.to validate_presence_of(:academic_year) }
    it { is_expected.to validate_presence_of(:file_format) }

    context "when file_format is careplus and team has careplus disabled" do
      before { export.file_format = "careplus" }

      it "is invalid" do
        expect(export).not_to be_valid
        expect(export.errors[:file_format]).to include(/not available/)
      end
    end

    context "when file_format is careplus and team has careplus enabled" do
      let(:team) do
        create(:team, :with_one_nurse, :with_careplus_enabled, programmes: [Programme.flu])
      end

      before { export.file_format = "careplus" }

      it { is_expected.to be_valid }
    end
  end

  describe "#file_formats" do
    context "when team has careplus disabled" do
      it "returns mavis and systm_one only" do
        expect(export.file_formats).to eq(%w[mavis systm_one])
      end
    end

    context "when team has careplus enabled" do
      let(:team) do
        create(:team, :with_one_nurse, :with_careplus_enabled, programmes: [Programme.flu])
      end

      it "includes careplus" do
        expect(export.file_formats).to eq(%w[mavis systm_one careplus])
      end
    end
  end

  describe "#expired?" do
    context "when status is expired" do
      before { export.status = "expired" }

      it "returns true" do
        expect(export.expired?).to be true
      end
    end

    context "when expired_at is in the past" do
      before do
        export.save!
        export.update!(expired_at: 1.hour.ago)
      end

      it "returns true" do
        expect(export.expired?).to be true
      end
    end

    context "when expired_at is in the future" do
      before do
        export.save!
        export.update!(expired_at: 1.hour.from_now)
      end

      it "returns false" do
        expect(export.expired?).to be false
      end
    end
  end

  describe "#set_expired_at!" do
    before do
      export.save!
      allow(Settings.vaccination_report_export).to receive(:retention_hours).and_return(168)
    end

    it "sets expired_at based on retention_hours" do
      export.set_expired_at!
      expect(export.expired_at).to be_within(1.minute).of(export.created_at + 168.hours)
    end
  end
end
