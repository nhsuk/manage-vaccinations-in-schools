# frozen_string_literal: true

describe VaccinationReportExportPolicy do
  subject(:policy) { described_class.new(user, export) }

  let(:team) { create(:team, :with_one_nurse, programmes: [Programme.flu]) }
  let(:user) { team.users.first }
  let(:export) do
    create(
      :vaccination_report_export,
      team:,
      user:,
      programme_type: "flu",
      file_format: "mavis"
    )
  end

  describe "#create?" do
    context "when user is team member with point of care access" do
      it { is_expected.to be_create }
    end

    context "when user is not in team" do
      let(:other_team) { create(:team, :with_one_nurse, programmes: [Programme.flu]) }
      let(:export) do
        build(
          :vaccination_report_export,
          team: other_team,
          user:,
          programme_type: "flu",
          file_format: "mavis"
        )
      end

      it { is_expected.not_to be_create }
    end
  end

  describe "#form_options?" do
    it { is_expected.to be_form_options }
  end

  describe "#index?" do
    it { is_expected.to be_index }
  end

  describe "#show?" do
    it { is_expected.to be_show }
  end

  describe "#download?" do
    context "when export is ready with file attached" do
      before do
        export.file.attach(
          io: StringIO.new("csv"),
          filename: "test.csv",
          content_type: "text/csv"
        )
        export.ready!
      end

      it { is_expected.to be_download }
    end

    context "when export is pending" do
      it { is_expected.not_to be_download }
    end
  end
end
