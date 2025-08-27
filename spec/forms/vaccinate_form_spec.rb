# frozen_string_literal: true

describe VaccinateForm do
  subject(:form) do
    described_class.new(programme:, current_user:, patient_session:)
  end

  let(:programme) { build(:programme) }
  let(:current_user) do
    build(:user, show_in_suppliers: user_designated_as_supplier)
  end
  let(:session) { build(:session, psd_enabled:) }
  let(:patient_session) { build(:patient_session, session:) }

  let(:psd_enabled) { false }
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
          current_user:
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

    context "when patient_session is nil" do
      let(:patient_session) { nil }

      it { should be(false) }
    end

    context "when patient_session is present" do
      before do
        allow(patient_session).to receive(:psd_added?).with(
          programme:
        ).and_return(psd_record_exists)
      end

      context "when operating under national protocol" do
        let(:psd_enabled) { false }
        let(:psd_record_exists) { false }
        let(:user_designated_as_supplier) { false }

        it "requires supplier ID" do
          expect(requires_supplied_by_user_id?).to be(true)
        end
      end

      context "when PSD is enabled for the session" do
        let(:psd_enabled) { true }
        let(:user_designated_as_supplier) { false }

        context "and no PSD record exists" do
          let(:psd_record_exists) { false }

          it "does not require supplier ID" do
            expect(requires_supplied_by_user_id?).to be(false)
          end
        end

        context "and PSD record exists" do
          let(:psd_record_exists) { true }

          it "does not require supplier ID" do
            expect(requires_supplied_by_user_id?).to be(false)
          end
        end
      end

      context "when PSD record exists for patient/programme" do
        let(:psd_enabled) { false }
        let(:psd_record_exists) { true }
        let(:user_designated_as_supplier) { false }

        it "does not require supplier ID" do
          expect(requires_supplied_by_user_id?).to be(false)
        end
      end

      context "when user is designated as a supplier" do
        let(:psd_enabled) { false }
        let(:psd_record_exists) { false }
        let(:user_designated_as_supplier) { true }

        it "does not require supplier ID" do
          expect(requires_supplied_by_user_id?).to be(false)
        end
      end

      context "when multiple exempting conditions are present" do
        context "PSD enabled AND user is supplier" do
          let(:psd_enabled) { true }
          let(:psd_record_exists) { false }
          let(:user_designated_as_supplier) { true }

          it "does not require supplier ID" do
            expect(requires_supplied_by_user_id?).to be(false)
          end
        end

        context "PSD record exists AND user is supplier" do
          let(:psd_enabled) { false }
          let(:psd_record_exists) { true }
          let(:user_designated_as_supplier) { true }

          it "does not require supplier ID" do
            expect(requires_supplied_by_user_id?).to be(false)
          end
        end

        context "PSD enabled AND PSD record exists" do
          let(:psd_enabled) { true }
          let(:psd_record_exists) { true }
          let(:user_designated_as_supplier) { false }

          it "does not require supplier ID" do
            expect(requires_supplied_by_user_id?).to be(false)
          end
        end

        context "all exempting conditions present" do
          let(:psd_enabled) { true }
          let(:psd_record_exists) { true }
          let(:user_designated_as_supplier) { true }

          it "does not require supplier ID" do
            expect(requires_supplied_by_user_id?).to be(false)
          end
        end
      end
    end
  end
end
