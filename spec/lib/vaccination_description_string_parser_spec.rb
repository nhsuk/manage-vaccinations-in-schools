# frozen_string_literal: true

describe VaccinationDescriptionStringParser do
  subject(:call) { described_class.call(string) }

  context "with an empty string" do
    let(:string) { "" }

    it { should be_nil }
  end

  {
    "Flu" => {
      programme_name: "Flu"
    },
    "Human Papillomavirus 1" => {
      programme_name: "HPV",
      dose_sequence: 1
    },
    "Td/IPV 2nd Scheduled Booster" => {
      programme_name: "Td/IPV",
      dose_sequence: "2nd Scheduled Booster"
    },
    "Meningococcal conjugate A,C, W135 + Y 1" => {
      programme_name: "MenACWY",
      dose_sequence: 1
    },
    "Measles/Mumps/Rubella 1" => {
      programme_name: "MMR",
      dose_sequence: 1
    },
    "Revaxis 1" => {
      vaccine_name: "Revaxis",
      dose_sequence: 1
    },
    "Gardasil9 1" => {
      vaccine_name: "Gardasil9",
      dose_sequence: 1
    },
    "MenQuadfi 1" => {
      vaccine_name: "MenQuadfi",
      dose_sequence: 1
    }
  }.each do |input, output|
    context "with #{input}" do
      let(:string) { input }

      it { should eq(output) }
    end
  end
end
