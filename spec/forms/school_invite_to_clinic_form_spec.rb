# frozen_string_literal: true

describe SchoolInviteToClinicForm do
  subject(:form) { described_class.new }

  describe "validations" do
    it { should validate_presence_of(:programme_types) }
  end
end
