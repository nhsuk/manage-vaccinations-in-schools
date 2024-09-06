# frozen_string_literal: true

RSpec.describe ProgrammesHelper, type: :helper do
  describe "#programme_academic_year" do
    subject(:programme_academic_year) do
      helper.programme_academic_year(programme)
    end

    let(:programme) { create(:programme, academic_year: 2024) }

    it { should eq("2024/25") }
  end
end
