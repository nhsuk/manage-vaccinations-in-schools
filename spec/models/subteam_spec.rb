# frozen_string_literal: true

# == Schema Information
#
# Table name: subteams
#
#  id                 :bigint           not null, primary key
#  email              :string           not null
#  name               :string           not null
#  phone              :string           not null
#  phone_instructions :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  organisation_id    :bigint           not null
#  reply_to_id        :uuid
#
# Indexes
#
#  index_subteams_on_organisation_id_and_name  (organisation_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#

describe Subteam do
  subject(:subteam) { build(:subteam) }

  it_behaves_like "a model with a normalised email address"
  it_behaves_like "a model with a normalised phone number"

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:phone) }
  end
end
