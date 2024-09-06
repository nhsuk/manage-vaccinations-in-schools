# frozen_string_literal: true

shared_examples_for "a CSVImportable model" do
  describe "validations" do
    it { should be_valid }

    it { should validate_presence_of(:csv_filename) }

    context "when the CSV has been removed and data exists" do
      before do
        subject.csv_removed_at = Time.zone.now
        subject.csv_data = "data"
      end

      it { should be_invalid }
    end
  end

  describe "#csv_removed?" do
    it "is false" do
      expect(subject.csv_removed?).to be false
    end

    context "when csv_removed_at is set" do
      before { subject.csv_removed_at = Time.zone.now }

      it "is true" do
        expect(subject.csv_removed?).to be true
      end
    end
  end

  describe "#remove!" do
    let(:today) { Time.zone.local(2020, 1, 1) }

    it "clears the data" do
      expect { subject.remove! }.to change(subject, :csv_data).to(nil)
    end

    it "sets the date/time" do
      expect { travel_to(today) { subject.remove! } }.to change(
        subject,
        :csv_removed_at
      ).from(nil).to(today)
    end
  end
end
