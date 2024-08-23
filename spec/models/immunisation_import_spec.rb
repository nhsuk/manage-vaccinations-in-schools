# frozen_string_literal: true

# == Schema Information
#
# Table name: immunisation_imports
#
#  id                            :bigint           not null, primary key
#  csv                           :text             not null
#  exact_duplicate_record_count  :integer
#  new_record_count              :integer
#  not_administered_record_count :integer
#  processed_at                  :datetime
#  recorded_at                   :datetime
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  campaign_id                   :bigint           not null
#  user_id                       :bigint           not null
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

  before do
    create(:location, :school, urn: "110158")
    create(:location, :school, urn: "120026")
    create(:location, :school, urn: "144012")
  end

  let(:academic_year) { 2023 }
  let(:campaign) { create(:campaign, :flu_all_vaccines, academic_year:) }
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
      let(:campaign) { create(:campaign, :flu_all_vaccines, academic_year:) }
      let(:file) { "valid_flu.csv" }

      it "populates the rows" do
        expect(immunisation_import).to be_valid
        expect(immunisation_import.rows).not_to be_empty
      end
    end

    context "with valid HPV rows" do
      let(:campaign) { create(:campaign, :hpv_all_vaccines, academic_year:) }
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
        expect(immunisation_import.errors).to include(:row_1)
      end
    end
  end

  describe "#process!" do
    subject(:process!) { immunisation_import.process! }

    context "with valid Flu rows" do
      let(:campaign) { create(:campaign, :flu_all_vaccines, academic_year:) }
      let(:file) { "valid_flu.csv" }

      it "creates locations, patients, and vaccination records" do
        # stree-ignore
        expect { process! }
          .to change(immunisation_import, :processed_at).from(nil)
          .and change(immunisation_import.vaccination_records, :count).by(7)
          .and not_change(immunisation_import.locations, :count)
          .and change(immunisation_import.patients, :count).by(7)
          .and change(immunisation_import.sessions, :count).by(1)
          .and change(PatientSession, :count).by(7)
          .and change(Batch, :count).by(4)

        # Second import should not duplicate the vaccination records if they're
        # identical.

        # stree-ignore
        expect { immunisation_import.process! }
          .to not_change(immunisation_import, :processed_at)
          .and not_change(immunisation_import.vaccination_records, :count)
          .and not_change(immunisation_import.locations, :count)
          .and not_change(immunisation_import.patients, :count)
          .and not_change(immunisation_import.sessions, :count)
          .and not_change(PatientSession, :count)
          .and not_change(Batch, :count)
      end

      it "stores statistics on the import" do
        # stree-ignore
        expect { process! }
          .to change(immunisation_import, :exact_duplicate_record_count).to(0)
          .and change(immunisation_import, :new_record_count).to(7)
          .and change(immunisation_import, :not_administered_record_count).to(4)
      end

      it "ignores and counts duplicate records" do
        build(:immunisation_import, campaign:, csv:, user:).record!
        csv.rewind

        process!
        expect(immunisation_import.exact_duplicate_record_count).to eq(7)
      end
    end

    context "with valid HPV rows" do
      let(:campaign) { create(:campaign, :hpv_all_vaccines, academic_year:) }
      let(:file) { "valid_hpv.csv" }

      it "creates locations, patients, and vaccination records" do
        # stree-ignore
        expect { process! }
          .to change(immunisation_import, :processed_at).from(nil)
          .and change(immunisation_import.vaccination_records, :count).by(7)
          .and not_change(immunisation_import.locations, :count)
          .and change(immunisation_import.patients, :count).by(7)
          .and change(immunisation_import.sessions, :count).by(1)
          .and change(PatientSession, :count).by(7)
          .and change(Batch, :count).by(5)

        # Second import should not duplicate the vaccination records if they're
        # identical.

        # stree-ignore
        expect { immunisation_import.process! }
          .to not_change(immunisation_import, :processed_at)
          .and not_change(immunisation_import.vaccination_records, :count)
          .and not_change(immunisation_import.locations, :count)
          .and not_change(immunisation_import.patients, :count)
          .and not_change(immunisation_import.sessions, :count)
          .and not_change(PatientSession, :count)
          .and not_change(Batch, :count)
      end

      it "stores statistics on the import" do
        # stree-ignore
        expect { process! }
          .to change(immunisation_import, :exact_duplicate_record_count).to(0)
          .and change(immunisation_import, :new_record_count).to(7)
          .and change(immunisation_import, :not_administered_record_count).to(0)
      end

      it "ignores and counts duplicate records" do
        build(:immunisation_import, campaign:, csv:, user:).record!
        csv.rewind

        process!
        expect(immunisation_import.exact_duplicate_record_count).to eq(7)
      end

      it "creates a new session for each date" do
        process!

        expect(immunisation_import.sessions.count).to eq(1)

        session = immunisation_import.sessions.first
        expect(session.date).to eq(Date.new(2024, 5, 14))
        expect(session.time_of_day).to eq("all_day")
      end
    end

    context "with an existing patient matching the name" do
      let(:campaign) { create(:campaign, :flu_all_vaccines, academic_year:) }
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
          6
        )
      end

      it "doesn't update the NHS number on the existing patient" do
        expect { process! }.not_to change(patient, :nhs_number).from(nil)
      end
    end
  end

  describe "#record!" do
    subject(:record!) { immunisation_import.record! }

    context "with valid Flu rows" do
      let(:campaign) { create(:campaign, :flu_all_vaccines, academic_year:) }
      let(:file) { "valid_flu.csv" }

      it "sets the recorded at time" do
        expect { record! }.to change(immunisation_import, :recorded_at).from(
          nil
        )
      end

      it "records the vaccination records" do
        expect { record! }.to change(VaccinationRecord.recorded, :count).from(
          0
        ).to(7)
      end
    end

    context "with valid HPV rows" do
      let(:campaign) { create(:campaign, :hpv_all_vaccines, academic_year:) }
      let(:file) { "valid_hpv.csv" }

      it "sets the recorded at time" do
        expect { record! }.to change(immunisation_import, :recorded_at).from(
          nil
        )
      end

      it "records the vaccination records" do
        expect { record! }.to change(VaccinationRecord.recorded, :count).from(
          0
        ).to(7)
      end
    end
  end
end
