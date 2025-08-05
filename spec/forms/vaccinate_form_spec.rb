# frozen_string_literal: true

describe VaccinateForm do
  subject(:form) { described_class.new(programme:) }

  let(:programme) { create(:programme) }

  describe "validations" do
    it do
      expect(form).to allow_values(true, false).for(
        :identity_check_confirmed_by_patient
      )
    end

    it do
      expect(form).to validate_length_of(
        :identity_check_confirmed_by_other_name
      ).is_at_most(300)
    end

    it do
      expect(form).to validate_length_of(
        :identity_check_confirmed_by_other_relationship
      ).is_at_most(300)
    end

    context "when confirmed by someone else" do
      subject(:form) do
        described_class.new(
          identity_check_confirmed_by_patient: false,
          programme:
        )
      end

      it do
        expect(form).to validate_presence_of(
          :identity_check_confirmed_by_other_name
        )
      end

      it do
        expect(form).to validate_presence_of(
          :identity_check_confirmed_by_other_relationship
        )
      end
    end

    it { should validate_length_of(:pre_screening_notes).is_at_most(1000) }
  end
end
