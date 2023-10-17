require "rails_helper"

RSpec.describe HealthAnswersList do
  let(:ha1) { create :health_question }
  let(:ha2) { create :health_question }
  let(:ha3) { create :health_question }

  describe "#initialize" do
    it "returns empty list by default" do
      list = HealthAnswersList.new

      expect(list.count).to eq 0
    end
  end

  describe "#each" do
    it "works with an empty set" do
      expect {
        HealthAnswersList.new.each { |_a| raise "Should not be called" }
      }.not_to raise_error
    end

    context "three health questions linked up" do
      before do
        ha1.update! next_question: ha2.id
        ha2.update! next_question: ha3.id
      end

      it "progresses through the list" do
        list = HealthAnswersList.new([ha1, ha2, ha3])

        expect { |b| list.each(&b) }.to yield_successive_args(ha1, ha2, ha3)
      end
    end
  end

  describe "#[]" do
    context "three health questions linked up" do
      before do
        ha1.update! next_question: ha2.id
        ha2.update! next_question: ha3.id
      end

      it "returns the nth health answer" do
        list = HealthAnswersList.new([ha1, ha2, ha3])

        expect(list[0]).to eq(ha1)
        expect(list[1]).to eq(ha2)
        expect(list[2]).to eq(ha3)
      end
    end
  end
end
