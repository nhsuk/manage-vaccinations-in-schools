# frozen_string_literal: true

describe TriageForm do
  subject(:form) { described_class.new }

  describe "validations" do
    it do
      expect(form).to validate_inclusion_of(:status).in_array(
        %w[
          ready_to_vaccinate
          do_not_vaccinate
          needs_follow_up
          delay_vaccination
        ]
      )
    end

    it { should_not validate_presence_of(:notes) }
    it { should validate_length_of(:notes).is_at_most(1000) }
  end
end
