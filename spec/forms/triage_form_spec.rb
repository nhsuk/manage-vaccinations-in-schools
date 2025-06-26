# frozen_string_literal: true

describe TriageForm do
  subject(:form) { described_class.new(patient_session:, programme:) }

  let(:programme) { create(:programme) }
  let(:patient_session) { create(:patient_session, programmes: [programme]) }

  describe "validations" do
    it do
      expect(form).to validate_inclusion_of(
        :status_and_vaccine_method
      ).in_array(form.status_and_vaccine_method_options)
    end

    it { should_not validate_presence_of(:notes) }
    it { should validate_length_of(:notes).is_at_most(1000) }
  end
end
