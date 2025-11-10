# frozen_string_literal: true

describe VaccinateForm do
  subject(:form) do
    described_class.new(programme:, current_user:, session_date:)
  end

  let(:programme) { CachedProgramme.sample }
  let(:current_user) do
    build(:user, show_in_suppliers: user_designated_as_supplier)
  end
  let(:session) { build(:session, psd_enabled:, national_protocol_enabled:) }
  let(:session_date) { session.session_dates.first }

  let(:psd_enabled) { false }
  let(:national_protocol_enabled) { false }
  let(:user_designated_as_supplier) { true }

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
          programme:,
          current_user:,
          session_date:
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

  describe "#requires_supplied_by_user_id?" do
    subject(:requires_supplied_by_user_id?) do
      form.requires_supplied_by_user_id?
    end

    context "when operating under national protocol" do
      let(:psd_enabled) { false }
      let(:national_protocol_enabled) { true }
      let(:user_designated_as_supplier) { false }

      it "requires supplier ID" do
        expect(requires_supplied_by_user_id?).to be(true)
      end
    end

    context "when user is designated as a supplier" do
      let(:psd_enabled) { false }
      let(:user_designated_as_supplier) { true }

      it "does not require supplier ID" do
        expect(requires_supplied_by_user_id?).to be(false)
      end
    end

    context "when PSD is enabled and user is designated as a supplier" do
      let(:psd_enabled) { true }
      let(:user_designated_as_supplier) { true }

      it "does not require supplier ID" do
        expect(requires_supplied_by_user_id?).to be(false)
      end
    end
  end
end
