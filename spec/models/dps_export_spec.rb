# frozen_string_literal: true

require "rails_helper"
require "csv"

describe DPSExport do
  describe "csv export" do
    subject(:csv) { described_class.new(vaccination_records).to_csv }

    let(:vaccination_records) { create_list(:vaccination_record, 3) }

    describe "header" do
      subject(:header) { csv.split("\n").first }

      it { should include '"DATE_AND_TIME"' }
    end
  end
end
