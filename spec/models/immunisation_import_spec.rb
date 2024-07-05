# frozen_string_literal: true

# == Schema Information
#
# Table name: immunisation_imports
#
#  id         :bigint           not null, primary key
#  csv        :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_immunisation_imports_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

describe ImmunisationImport do
  subject { described_class.create!(csv:, user:) }

  let(:file) { "nivs.csv" }
  let(:csv) { fixture_file_upload("spec/fixtures/immunisation_import/#{file}") }
  let(:user) { create(:user) }
  let(:patient_session) { create(:patient_session, user:) }

  it { should validate_presence_of(:csv) }

  describe "#process!" do
    it "creates vaccination records" do
      # TEMPORARY: Pass in a dummy patient session. We will iterate this out.
      expect { subject.process!(patient_session:) }.to change(
        VaccinationRecord,
        :count
      ).by(11)
    end
  end
end
