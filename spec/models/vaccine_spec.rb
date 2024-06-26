# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccines
#
#  id         :bigint           not null, primary key
#  brand      :text
#  dose       :decimal(, )
#  gtin       :text
#  method     :integer
#  supplier   :text
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require "rails_helper"

describe Vaccine do
  describe "#contains_gelatine?" do
    it "returns true if the vaccine is a nasal flu vaccine" do
      vaccine = FactoryBot.build(:vaccine, :fluenz_tetra)
      expect(vaccine.contains_gelatine?).to be true
    end

    it "returns false if the vaccine is an injected flu vaccine" do
      vaccine = FactoryBot.build(:vaccine, :fluarix_tetra)
      expect(vaccine.contains_gelatine?).to be false
    end

    it "returns false if the vaccine is not a flu vaccine" do
      vaccine = FactoryBot.build(:vaccine, :gardasil_9)
      expect(vaccine.contains_gelatine?).to be false
    end
  end
end
