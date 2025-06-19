# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccines
#
#  id                  :bigint           not null, primary key
#  brand               :text             not null
#  discontinued        :boolean          default(FALSE), not null
#  dose_volume_ml      :decimal(, )      not null
#  manufacturer        :text             not null
#  method              :integer          not null
#  nivs_name           :text             not null
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

  describe "#contains_gelatine?" do
    subject { vaccine.contains_gelatine? }

    context "with a nasal Flu vaccine" do
      let(:vaccine) { build(:vaccine, :fluenz_tetra) }

      it { should be(true) }
    end

    context "with an injected Flu vaccine" do
      let(:vaccine) { build(:vaccine, :quadrivalent_influenza) }

      it { should be(false) }
    end

    context "with an HPV vaccine" do
      let(:vaccine) { build(:vaccine, :gardasil_9) }

      it { should be(false) }
    end
  end

  describe "#can_be_half_dose?" do
    subject { vaccine.can_be_half_dose? }

    context "with a nasal Flu vaccine" do
      let(:vaccine) { build(:vaccine, :fluenz_tetra) }

      it { should be(true) }
    end

    context "with an injected Flu vaccine" do
      let(:vaccine) { build(:vaccine, :quadrivalent_influenza) }

      it { should be(false) }
    end

    context "with an HPV vaccine" do
      let(:vaccine) { build(:vaccine, :gardasil_9) }

      it { should be(false) }
    end
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
end
