# == Schema Information
#
# Table name: local_authorities
#
#  end_date                  :date
#  gias_local_authority_code :integer
#  gov_uk_slug               :string
#  gss_code                  :string
#  local_authority_code      :string           not null, primary key
#  nation                    :string
#  official_name             :string
#  region                    :string
#  short_name                :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
# Indexes
#
#  index_local_authorities_on_created_at             (created_at)
#  index_local_authorities_on_gss_code               (gss_code) UNIQUE
#  index_local_authorities_on_local_authority_code   (local_authority_code) UNIQUE
#  index_local_authorities_on_nation_and_short_name  (nation,short_name)
#  index_local_authorities_on_short_name             (short_name)
#

describe LocalAuthority, type: :model do
  describe ".from_my_society_import_row" do
    let(:result) { described_class.from_my_society_import_row(row) }
    let(:row) do 
      {
        'local-authority-code' => "BED",
        'gss-code' => "E06000055",
        'gov-uk-slug' => "bedford",
        'official-name' => "Bedford Borough Council",
        'nice-name' => "Bedford",
        'nation' => "England",
        'region' => "East of England",
        'end-date' => "2009-04-01",
      }
    end

    it "returns a LocalAuthority" do
      expect(result).to be_a(described_class)
    end

    describe "the result" do
      it "is not saved" do
        expect(result.persisted?).to eq(false)
      end

      it "has the expected attributes" do
        expect(result).to have_attributes({
          'local_authority_code' => "BED",
          'gss_code' => "E06000055",
          'gov_uk_slug' => "bedford",
          'official_name' => "Bedford Borough Council",
          'short_name' => "Bedford",
          'nation' => "England",
          'region' => "East of England",
          'end_date' => "2009-04-01".to_date,
        })
      end
    end
  end
end
