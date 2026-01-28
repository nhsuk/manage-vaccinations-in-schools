# frozen_string_literal: true

describe EthnicityConcern do
  let(:any_other_background) { :white_any_other_white_background }
  let(:non_any_other_background) { :white_irish }

  describe "#normalise_ethnic_background_other" do
    subject(:patient) do
      build(
        :patient,
        ethnic_group: :white,
        ethnic_background: ethnic_background,
        ethnic_background_other: "Some detail"
      )
    end

    before { patient.valid? }

    context "when ethnic_background does not require additional details" do
      let(:ethnic_background) { non_any_other_background }

      it "clears ethnic_background_other" do
        expect(patient.ethnic_background_other).to be_nil
      end
    end

    context "when ethnic_background requires additional details" do
      let(:ethnic_background) { any_other_background }

      it "keeps ethnic_background_other" do
        expect(patient.ethnic_background_other).to eq("Some detail")
      end
    end
  end

  describe "#validate_ethnic_background_other?" do
    subject(:patient) do
      create(
        :patient,
        ethnic_group: :white,
        ethnic_background: non_any_other_background,
        ethnic_background_other: nil
      )
    end

    context "when ethnic_background changes" do
      before { patient.ethnic_background = any_other_background }

      it { expect(patient.validate_ethnic_background_other?).to be(true) }
    end

    context "when only unrelated attributes change" do
      before { patient.given_name = "Updated" }

      it { expect(patient.validate_ethnic_background_other?).to be(false) }
    end
  end

  describe "#require_ethnic_background_other?" do
    subject(:patient) do
      create(
        :patient,
        ethnic_group: :white,
        ethnic_background: non_any_other_background,
        ethnic_background_other: nil
      )
    end

    context "when background requires details and the background changes" do
      before { patient.ethnic_background = any_other_background }

      it { expect(patient.require_ethnic_background_other?).to be(true) }
    end

    context "when background does not require additional details" do
      before do
        patient.ethnic_background =
          :white_english_welsh_scottish_northern_irish_or_british
      end

      it { expect(patient.require_ethnic_background_other?).to be(false) }
    end
  end

  describe "validations" do
    subject(:patient) do
      build(
        :patient,
        ethnic_group: :white,
        ethnic_background: any_other_background,
        ethnic_background_other: ethnic_background_other
      )
    end

    context "when ethnic_background requires additional details" do
      context "when ethnic_background_other is blank" do
        let(:ethnic_background_other) { nil }

        it "is invalid" do
          expect(patient).not_to be_valid
          expect(patient.errors).to have_key(:ethnic_background_other)
        end
      end

      context "when ethnic_background_other is too long" do
        let(:ethnic_background_other) { "a" * 301 }

        it "is invalid" do
          expect(patient).not_to be_valid
          expect(patient.errors).to have_key(:ethnic_background_other)
        end
      end

      context "when ethnic_background_other is present" do
        let(:ethnic_background_other) { "Some detail" }

        it { expect(patient).to be_valid }
      end
    end

    context "when ethnicity fields are unchanged" do
      subject(:patient) do
        create(
          :patient,
          ethnic_group: :white,
          ethnic_background: any_other_background,
          ethnic_background_other: "Some detail"
        )
      end

      it "does not require ethnic_background_other when only unrelated fields change" do
        patient.given_name = "Updated"

        aggregate_failures do
          expect(patient.require_ethnic_background_other?).to be(false)

          patient.valid?
          expect(patient.errors[:ethnic_background_other]).to be_empty
        end
      end
    end

    context "when the background changes to a non-any-other option" do
      subject(:patient) do
        create(
          :patient,
          ethnic_group: :white,
          ethnic_background: any_other_background,
          ethnic_background_other: "Some detail"
        )
      end

      it "clears ethnic_background_other" do
        patient.ethnic_background = non_any_other_background

        patient.valid?

        expect(patient.ethnic_background_other).to be_nil
      end
    end
  end
end
