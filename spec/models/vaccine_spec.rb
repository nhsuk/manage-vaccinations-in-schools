# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccines
#
#  id                  :bigint           not null, primary key
#  brand               :text             not null
#  contains_gelatine   :boolean          not null
#  discontinued        :boolean          default(FALSE), not null
#  disease_types       :enum             default([]), not null, is an Array
#  dose_volume_ml      :decimal(, )      not null
#  manufacturer        :text             not null
#  method              :integer          not null
#  nivs_name           :string
#  programme_type      :enum             not null
#  side_effects        :integer          default([]), not null, is an Array
#  snomed_product_code :string           not null
#  snomed_product_term :string           not null
#  upload_name         :text             not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_vaccines_on_manufacturer_and_brand  (manufacturer,brand) UNIQUE
#  index_vaccines_on_programme_type          (programme_type)
#  index_vaccines_on_snomed_product_code     (snomed_product_code) UNIQUE
#  index_vaccines_on_snomed_product_term     (snomed_product_term) UNIQUE
#  index_vaccines_on_upload_name             (upload_name) UNIQUE
#

describe Vaccine do
  describe "validations" do
    it { should validate_inclusion_of(:method).in_array(%w[injection nasal]) }
  end

  describe "#available_delivery_methods" do
    subject { vaccine.available_delivery_methods }

    context "with an injection vaccine" do
      let(:vaccine) { build(:vaccine, :injection) }

      it { should eq(%w[intramuscular subcutaneous]) }
    end

    context "with a nasal vaccine" do
      let(:vaccine) { build(:vaccine, :nasal) }

      it { should eq(%w[nasal_spray]) }
    end
  end

  describe "#snomed_procedure_code" do
    subject { vaccine.snomed_procedure_code(dose_sequence:) }

    let(:dose_sequence) { nil }

    context "with an injection flu vaccine" do
      let(:vaccine) { build(:vaccine, :flu, :injection) }

      context "with first dose" do
        let(:dose_sequence) { 1 }

        it { should eq("985151000000100") }
      end

      context "and second dose" do
        let(:dose_sequence) { 2 }

        it { should eq("985171000000109") }
      end
    end

    context "with a nasal flu vaccine" do
      let(:vaccine) { build(:vaccine, :flu, :nasal) }

      context "with first dose" do
        let(:dose_sequence) { 1 }

        it { should eq("884861000000100") }
      end

      context "and second dose" do
        let(:dose_sequence) { 2 }

        it { should eq("884881000000109") }
      end
    end

    context "with an MMR vaccine" do
      let(:vaccine) { build(:vaccine, :mmr) }

      context "with first dose" do
        let(:dose_sequence) { 1 }

        it { should eq("38598009") }
      end

      context "and second dose" do
        let(:dose_sequence) { 2 }

        it { should eq("170433008") }
      end
    end

    context "with an MMRV vaccine" do
      let(:vaccine) { build(:vaccine, :mmrv) }

      context "with first dose" do
        let(:dose_sequence) { 1 }

        it { should eq("432636005") }
      end

      context "and second dose" do
        let(:dose_sequence) { 2 }

        it { should eq("433733003") }
      end
    end
  end

  describe "#snomed_procedure_term" do
    subject(:procedure_term) { vaccine.snomed_procedure_term(dose_sequence:) }

    let(:dose_sequence) { 1 }

    context "with flu injection vaccine" do
      let(:vaccine) { build(:vaccine, :flu, :injection) }

      context "with first dose" do
        let(:dose_sequence) { 1 }

        it do
          should eq(
                   "Administration of first inactivated seasonal influenza vaccination"
                 )
        end
      end

      context "with second dose" do
        let(:dose_sequence) { 2 }

        it do
          should eq(
                   "Administration of second inactivated seasonal influenza vaccination"
                 )
        end
      end
    end

    context "with flu nasal vaccine" do
      let(:vaccine) { build(:vaccine, :flu, :nasal) }

      context "with first dose" do
        let(:dose_sequence) { 1 }

        it do
          should eq(
                   "Administration of first intranasal seasonal influenza vaccination"
                 )
        end
      end

      context "with second dose" do
        let(:dose_sequence) { 2 }

        it do
          should eq(
                   "Administration of second intranasal seasonal influenza vaccination"
                 )
        end
      end
    end

    context "with an MMR vaccine" do
      let(:vaccine) { build(:vaccine, :mmr) }

      context "with first dose" do
        let(:dose_sequence) { 1 }

        it do
          expect(procedure_term).to eq(
            "Administration of vaccine product containing only Measles " \
              "morbillivirus and Mumps orthorubulavirus and Rubella virus " \
              "antigens"
          )
        end
      end

      context "with second dose" do
        let(:dose_sequence) { 2 }

        it do
          expect(procedure_term).to eq(
            "Administration of second dose of vaccine product containing only " \
              "Measles morbillivirus and Mumps orthorubulavirus and Rubella virus " \
              "antigens"
          )
        end
      end
    end

    context "with an MMRV vaccine" do
      let(:vaccine) { build(:vaccine, :mmrv) }

      context "with first dose" do
        let(:dose_sequence) { 1 }

        it do
          expect(procedure_term).to eq(
            "Administration of vaccine product containing only Human " \
              "alphaherpesvirus 3 and Measles morbillivirus and Mumps " \
              "orthorubulavirus and Rubella virus antigens"
          )
        end
      end

      context "with second dose" do
        let(:dose_sequence) { 2 }

        it do
          expect(procedure_term).to eq(
            "Administration of second dose of vaccine product containing " \
              "only Human alphaherpesvirus 3 and Measles morbillivirus and " \
              "Mumps orthorubulavirus and Rubella virus antigens"
          )
        end
      end
    end
  end
end
