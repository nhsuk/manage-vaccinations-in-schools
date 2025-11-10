# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccines
#
#  id                  :bigint           not null, primary key
#  brand               :text             not null
#  contains_gelatine   :boolean          not null
#  discontinued        :boolean          default(FALSE), not null
#  dose_volume_ml      :decimal(, )      not null
#  manufacturer        :text             not null
#  method              :integer          not null
#  nivs_name           :text             not null
#  programme_type      :enum             not null
#  side_effects        :integer          default([]), not null, is an Array
#  snomed_product_code :string           not null
#  snomed_product_term :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  programme_id        :bigint           not null
#
# Indexes
#
#  index_vaccines_on_manufacturer_and_brand  (manufacturer,brand) UNIQUE
#  index_vaccines_on_nivs_name               (nivs_name) UNIQUE
#  index_vaccines_on_programme_id            (programme_id)
#  index_vaccines_on_snomed_product_code     (snomed_product_code) UNIQUE
#  index_vaccines_on_snomed_product_term     (snomed_product_term) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (programme_id => programmes.id)
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

      context "and first dose" do
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

      context "and first dose" do
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

      it { should eq("38598009") }
    end
  end
end
