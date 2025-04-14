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
  describe "validation" do
    it { should validate_inclusion_of(:method).in_array(%w[injection nasal]) }
  end

  describe "#contains_gelatine?" do
    it "returns true if the vaccine is a nasal flu vaccine" do
      vaccine = build(:vaccine, :fluenz_tetra)
      expect(vaccine.contains_gelatine?).to be true
    end

    it "returns false if the vaccine is an injected flu vaccine" do
      vaccine = build(:vaccine, :quadrivalent_influenza)
      expect(vaccine.contains_gelatine?).to be false
    end

    it "returns false if the vaccine is not a flu vaccine" do
      vaccine = build(:vaccine, :gardasil_9)
      expect(vaccine.contains_gelatine?).to be false
    end
  end

  describe "#seasonal?" do
    subject(:seasonal?) { vaccine.seasonal? }

    context "with a Flu vaccine" do
      let(:vaccine) { build(:vaccine, :flu) }

      it { should be(true) }
    end

    context "with an HPV vaccine" do
      let(:vaccine) { build(:vaccine, :hpv) }

      it { should be(false) }
    end
  end

  describe "#available_delivery_methods" do
    subject(:available_delivery_methods) { vaccine.available_delivery_methods }

    context "with a Flu vaccine" do
      let(:vaccine) { build(:vaccine, :flu) }

      it { should eq(%w[nasal_spray]) }
    end

    context "with an HPV vaccine" do
      let(:vaccine) { build(:vaccine, :hpv) }

      it { should eq(%w[intramuscular subcutaneous]) }
    end

    context "with an MenACWY vaccine" do
      let(:vaccine) { build(:vaccine, :menacwy) }

      it { should eq(%w[intramuscular subcutaneous]) }
    end

    context "with an Td/IPV vaccine" do
      let(:vaccine) { build(:vaccine, :td_ipv) }

      it { should eq(%w[intramuscular subcutaneous]) }
    end
  end
end
