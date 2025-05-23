# frozen_string_literal: true

describe VaccinateForm do
  subject(:form) { described_class.new }

  describe "validations" do
    it { should validate_length_of(:pre_screening_notes).is_at_most(1000) }
  end
end
