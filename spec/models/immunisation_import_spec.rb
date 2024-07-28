# frozen_string_literal: true

# == Schema Information
#
# Table name: immunisation_imports
#
#  id          :bigint           not null, primary key
#  csv         :text             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  campaign_id :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_immunisation_imports_on_campaign_id  (campaign_id)
#  index_immunisation_imports_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id)
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

describe ImmunisationImport, type: :model do
  subject(:immunisation_import) do
    create(:immunisation_import, campaign:, csv:, user:)
  end

  let(:campaign) { create(:campaign) }
  let(:file) { "valid_flu.csv" }
  let(:csv) { fixture_file_upload("spec/fixtures/immunisation_import/#{file}") }
  let(:team) { create(:team, ods_code: "R1L") }
  let(:user) { create(:user, teams: [team]) }

  it { should validate_presence_of(:csv) }

  describe "#load_data!" do
    before { immunisation_import.load_data! }

    context "with malformed CSV" do
      let(:file) { "malformed.csv" }

      it "is invalid" do
        expect(immunisation_import).to be_invalid
        expect(immunisation_import.errors[:csv]).to include(/correct format/)
      end
    end

    context "with empty CSV" do
      let(:file) { "empty.csv" }

      it "is invalid" do
        expect(immunisation_import).to be_invalid
        expect(immunisation_import.errors[:csv]).to include(/one record/)
      end
    end

    context "with missing headers" do
      let(:file) { "missing_headers.csv" }

      it "is invalid" do
        expect(immunisation_import).to be_invalid
        expect(immunisation_import.errors[:csv]).to include(/missing/)
      end
    end
  end

  describe "#parse_rows!" do
    before { immunisation_import.parse_rows! }

    context "with valid Flu rows" do
      let(:campaign) { create(:campaign, :flu) }
      let(:file) { "valid_flu.csv" }

      it "populates the rows" do
        expect(immunisation_import).to be_valid
        expect(immunisation_import.rows).not_to be_empty
      end
    end

    context "with valid HPV rows" do
      let(:campaign) { create(:campaign, :hpv) }
      let(:file) { "valid_hpv.csv" }

      it "populates the rows" do
        expect(immunisation_import).to be_valid
        expect(immunisation_import.rows).not_to be_empty
      end
    end

    context "with invalid rows" do
      let(:file) { "invalid_rows.csv" }

      it "is invalid" do
        expect(immunisation_import).to be_invalid
        expect(immunisation_import.errors).to include(:row_2)
      end
    end
  end

  describe "#process!" do
    subject(:process!) { immunisation_import.process! }

    context "with valid Flu rows" do
      let(:campaign) { create(:campaign, :flu) }
      let(:file) { "valid_flu.csv" }

      it "creates locations, patients, and vaccination records" do
        # stree-ignore
        expect { process! }
          .to change(immunisation_import.vaccination_records, :count).by(11)
          .and change(immunisation_import.locations, :count).by(4)
          .and change(immunisation_import.patients, :count).by(11)
          .and change(immunisation_import.sessions, :count).by(4)
          .and change(PatientSession, :count).by(11)

        # Second import should not duplicate the vaccination records if they're
        # identical.

        # stree-ignore
        expect { immunisation_import.process! }
          .to not_change(immunisation_import.vaccination_records, :count)
          .and not_change(immunisation_import.locations, :count)
          .and not_change(immunisation_import.patients, :count)
          .and not_change(immunisation_import.sessions, :count)
          .and not_change(PatientSession, :count)
      end
    end

    context "with valid HPV rows" do
      let(:campaign) { create(:campaign, :hpv) }
      let(:file) { "valid_hpv.csv" }

      it "creates locations, patients, and vaccination records" do
        # stree-ignore
        expect { process! }
          .to change(immunisation_import.vaccination_records, :count).by(7)
          .and change(immunisation_import.locations, :count).by(1)
          .and change(immunisation_import.patients, :count).by(7)
          .and change(immunisation_import.sessions, :count).by(1)
          .and change(PatientSession, :count).by(7)

        # Second import should not duplicate the vaccination records if they're
        # identical.

        # stree-ignore
        expect { immunisation_import.process! }
          .to not_change(immunisation_import.vaccination_records, :count)
          .and not_change(immunisation_import.locations, :count)
          .and not_change(immunisation_import.patients, :count)
          .and not_change(immunisation_import.sessions, :count)
          .and not_change(PatientSession, :count)
      end
    end

    context "with an existing patient matching the name" do
      let(:campaign) { create(:campaign, :flu) }
      let(:file) { "valid_flu.csv" }

      let!(:patient) do
        create(
          :patient,
          first_name: "Chyna",
          last_name: "Pickle",
          date_of_birth: Date.new(2012, 9, 12),
          nhs_number: nil
        )
      end

      it "doesn't create an additional patient" do
        expect { process! }.to change(immunisation_import.patients, :count).by(
          10
        )
      end

      it "doesn't update the NHS number on the existing patient" do
        expect { process! }.not_to change(patient, :nhs_number).from(nil)
      end
    end
  end
end
