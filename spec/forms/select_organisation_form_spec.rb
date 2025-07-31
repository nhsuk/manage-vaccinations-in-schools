# frozen_string_literal: true

describe SelectOrganisationForm do
  subject(:form) { described_class.new(current_user:) }

  let(:organisation) { create(:organisation) }
  let(:current_user) { create(:user, organisations: [organisation]) }

  before { create(:organisation) }

  describe "validations" do
    it do
      expect(form).to validate_inclusion_of(:organisation_id).in_array(
        [organisation.id]
      )
    end
  end
end
