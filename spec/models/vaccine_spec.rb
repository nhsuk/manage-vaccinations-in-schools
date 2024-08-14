# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccines
#
#  id                  :bigint           not null, primary key
#  brand               :text             not null
#  discontinued        :boolean          default(FALSE), not null
#  dose                :decimal(, )      not null
#  gtin                :text
#  manufacturer        :text             not null
#  method              :integer          not null
#  nivs_name           :text             not null
#  snomed_product_code :string           not null
#  snomed_product_term :string           not null
#  type                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_vaccines_on_gtin                    (gtin) UNIQUE
#  index_vaccines_on_manufacturer_and_brand  (manufacturer,brand) UNIQUE
#  index_vaccines_on_nivs_name               (nivs_name) UNIQUE
#  index_vaccines_on_snomed_product_code     (snomed_product_code) UNIQUE
#  index_vaccines_on_snomed_product_term     (snomed_product_term) UNIQUE
#

require "rails_helper"

describe Vaccine, type: :model do
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

  describe "#maximum_dose_sequence" do
    subject(:maximum_dose_sequence) { vaccine.maximum_dose_sequence }

    context "with a Flu vaccine" do
      let(:vaccine) { build(:vaccine, :flu) }

      it { should eq(1) }
    end

    context "with an HPV vaccine" do
      let(:vaccine) { build(:vaccine, :hpv) }

      it { should eq(3) }
    end
  end

  describe "#seasonal?" do
    it "returns true if the vaccine is a flu vaccine" do
      vaccine = build(:vaccine, :flu)
      expect(vaccine.seasonal?).to be true
    end

    it "returns false for HPV" do
      vaccine = build(:vaccine, :gardasil_9)
      expect(vaccine.seasonal?).to be false
    end

    it "raises an error for an unknown vaccine type" do
      vaccine = build(:vaccine, type: "unknown")
      expect { vaccine.seasonal? }.to raise_error(NotImplementedError)
    end
  end
end
