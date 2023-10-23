# == Schema Information
#
# Table name: consent_forms
#
#  id                        :bigint           not null, primary key
#  address_line_1            :string
#  address_line_2            :string
#  address_postcode          :string
#  address_town              :string
#  common_name               :text
#  contact_injection         :boolean
#  contact_method            :integer
#  contact_method_other      :text
#  date_of_birth             :date
#  first_name                :text
#  gp_name                   :string
#  gp_response               :integer
#  health_answers            :jsonb            not null
#  last_name                 :text
#  parent_email              :string
#  parent_name               :string
#  parent_phone              :string
#  parent_relationship       :integer
#  parent_relationship_other :string
#  reason                    :integer
#  reason_notes              :text
#  recorded_at               :datetime
#  response                  :integer
#  use_common_name           :boolean
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  session_id                :bigint           not null
#
# Indexes
#
#  index_consent_forms_on_session_id  (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (session_id => sessions.id)
#
require "rails_helper"

RSpec.describe ConsentForm, type: :model do
  describe "Validations" do
    let(:use_common_name) { false }
    let(:parent_relationship) { nil }
    let(:contact_method) { nil }
    let(:response) { nil }
    let(:reason) { nil }
    let(:gp_response) { nil }
    subject do
      build(
        :consent_form,
        form_step:,
        use_common_name:,
        parent_relationship:,
        contact_method:,
        response:,
        reason:,
        gp_response:
      )
    end

    context "when form_step is nil" do
      let(:form_step) { nil }

      it { should validate_presence_of(:first_name).on(:update) }
      it { should validate_presence_of(:last_name).on(:update) }

      it { should validate_presence_of(:date_of_birth).on(:update) }

      it { should_not validate_presence_of(:is_this_their_school).on(:update) }

      it { should validate_presence_of(:parent_name).on(:update) }
      it { should validate_presence_of(:parent_relationship).on(:update) }
      it { should validate_presence_of(:parent_email).on(:update) }

      it { should validate_presence_of(:response).on(:update) }
    end

    context "when form_step is :name" do
      let(:form_step) { :name }

      it { should validate_presence_of(:first_name).on(:update) }
      it { should validate_presence_of(:last_name).on(:update) }

      context "when use_common_name is true" do
        let(:use_common_name) { true }

        it { should validate_presence_of(:common_name).on(:update) }
      end
    end

    context "when form_step is :date_of_birth" do
      let(:form_step) { :date_of_birth }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:first_name).on(:update) }
      end

      it { should validate_presence_of(:date_of_birth).on(:update) }
      # it { should validate_comparison_of(:date_of_birth)
      #       .is_less_than(Time.zone.today)
      #       .is_greater_than_or_equal_to(22.years.ago.to_date)
      #       .is_less_than_or_equal_to(3.years.ago.to_date)
      #       .on(:update) }
    end

    context "when form_step is :school" do
      let(:form_step) { :school }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:first_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
      end

      it { should validate_presence_of(:is_this_their_school).on(:update) }
      it do
        should validate_inclusion_of(:is_this_their_school).in_array(
                 %w[yes no]
               ).on(:update)
      end
    end

    context "when form_step is :parent" do
      let(:form_step) { :parent }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:first_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
      end

      it { should_not validate_presence_of(:is_this_their_school).on(:update) }

      it { should validate_presence_of(:parent_name).on(:update) }
      it { should validate_presence_of(:parent_relationship).on(:update) }
      it { should validate_presence_of(:parent_email).on(:update) }

      it { should_not allow_value("invalid").for(:parent_email).on(:update) }
      it { should allow_value("foo@foo.com").for(:parent_email).on(:update) }

      context "when parent_relationship is 'other'" do
        let(:parent_relationship) { "other" }

        it do
          should validate_presence_of(:parent_relationship_other).on(:update)
        end
      end
    end

    context "when form_step is :consent" do
      let(:form_step) { :consent }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:first_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
        it { should validate_presence_of(:parent_name).on(:update) }
      end

      it { should validate_presence_of(:response).on(:update) }
    end

    context "when form_step is :reason" do
      let(:response) { "refused" }
      let(:form_step) { :reason }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:first_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
        it { should validate_presence_of(:parent_name).on(:update) }
      end

      it { should validate_presence_of(:reason).on(:update) }
    end

    context "when form_step is :injection" do
      let(:response) { "refused" }
      let(:reason) { "contains_gelatine" }
      let(:form_step) { :injection }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:first_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
        it { should validate_presence_of(:parent_name).on(:update) }
        it { should validate_presence_of(:reason).on(:update) }
      end

      # This prints a warning because boolean fields always get converted to
      # false when they are blank. As such we can't check for this validation.
      # it do
      #   should validate_inclusion_of(:contact_injection).in_array(
      #            [true, false]
      #          ).on(:update)
      # end
    end

    context "when form_step is :gp" do
      let(:response) { "given" }
      let(:form_step) { :gp }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:first_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
        it { should validate_presence_of(:parent_name).on(:update) }
      end

      it { should validate_presence_of(:gp_response).on(:update) }

      context "when gp_response is 'yes'" do
        let(:gp_response) { "yes" }

        it { should validate_presence_of(:gp_name).on(:update) }
      end
    end

    context "when form_step is :address" do
      let(:response) { "given" }
      let(:form_step) { :address }

      context "runs validations from previous steps" do
        it { should validate_presence_of(:first_name).on(:update) }
        it { should validate_presence_of(:date_of_birth).on(:update) }
        it { should validate_presence_of(:parent_name).on(:update) }
        it { should validate_presence_of(:gp_response).on(:update) }
      end

      it { should validate_presence_of(:address_line_1).on(:update) }
      it { should validate_presence_of(:address_town).on(:update) }
      it { should validate_presence_of(:address_postcode).on(:update) }

      it do
        should_not allow_value("invalid").for(:address_postcode).on(:update)
      end
    end
  end

  describe "#full_name" do
    it "returns the full name as a string" do
      consent_form = build(:consent_form, first_name: "John", last_name: "Doe")
      expect(consent_form.full_name).to eq("John Doe")
    end
  end

  describe "#form_steps" do
    it "asks for contact method if phone is specified" do
      consent_form = build(:consent_form, parent_phone: "0123456789")
      expect(consent_form.form_steps).to include(:contact_method)
    end

    it "does not ask for reason when patient gives consent" do
      consent_form = build(:consent_form, response: "given")
      expect(consent_form.form_steps).not_to include(:reason)
      expect(consent_form.form_steps).not_to include(:injection)
    end

    it "ask for reason when patient refuses with an ineligible reason" do
      consent_form =
        build(:consent_form, response: "refused", reason: "already_received")
      expect(consent_form.form_steps).to include(:reason)
      expect(consent_form.form_steps).not_to include(:injection)
    end

    it "ask for reason when patient refuses with an eligible reason" do
      consent_form =
        build(:consent_form, response: "refused", reason: "contains_gelatine")
      expect(consent_form.form_steps).to include(:reason)
      expect(consent_form.form_steps).to include(:injection)
    end

    it "does not ask for gp details when patient refuses consent" do
      consent_form = build(:consent_form, response: "refused")
      expect(consent_form.form_steps).not_to include(:gp)
    end

    it "asks for gp details, address when patient gives consent" do
      consent_form = build(:consent_form, response: "given")
      expect(consent_form.form_steps).to include(:gp)
      expect(consent_form.form_steps).to include(:address)
    end
  end

  describe "#address_postcode=" do
    it "formats the postcode" do
      consent_form = build(:consent_form, address_postcode: "sw1a1aa")
      expect(consent_form.address_postcode).to eq("SW1A 1AA")
    end

    it "converts nil to empty string" do
      consent_form = build(:consent_form, address_postcode: nil)
      expect(consent_form.address_postcode).to eq("")
    end
  end
end
