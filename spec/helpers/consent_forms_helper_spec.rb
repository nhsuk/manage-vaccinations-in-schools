# frozen_string_literal: true

describe ConsentFormsHelper, type: :helper do
  include ActionView::Helpers

  before do
    # For some reason the helper doesn't include this in the test environment.
    # There may be some other way to achieve this, but this works for now.
    described_class.include Wicked::Controller::Concerns::Path
  end

  describe "#health_question_backlink_path" do
    let(:consent_form) do
      create(:consent_form, :with_health_answers_asthma_branching)
    end
    let(:health_answer) { consent_form.health_answers.first }
    let(:final_wizard_path) { "final_wizard_path" }
    let(:previous_wizard_path) { "previous_wizard_path" }
    let(:previous_health_question_wizard_path) do
      "previous_health_question_wizard_path"
    end

    before do
      allow(helper).to receive(:wizard_path).with(
        Wicked::FINISH_STEP
      ).and_return(final_wizard_path)

      allow(helper).to receive(:wizard_path).with(
        "health-question",
        { question_number: 2 }
      ).and_return(previous_health_question_wizard_path)

      allow(helper).to receive(:previous_wizard_path).and_return(
        previous_wizard_path
      )
    end

    context "answering the first health question" do
      it "returns a link to the previous step" do
        params[:question_number] = "0"

        expect(
          helper.health_question_backlink_path(consent_form, health_answer)
        ).to eq previous_wizard_path
      end
    end

    context "answering a follow-up health question" do
      it "returns a link to the previous step" do
        # question 1 is a follow-up in our test data
        params[:question_number] = "1"

        expect(
          helper.health_question_backlink_path(consent_form, health_answer)
        ).to eq previous_health_question_wizard_path
      end
    end

    context "changing the answer to the first health question" do
      it "returns a link to the finish step" do
        params[:question_number] = "0"
        session[:follow_up_changes_start_page] = "0"

        expect(
          helper.health_question_backlink_path(consent_form, health_answer)
        ).to eq final_wizard_path
      end
    end

    context "changing the answer to a follow-up health question" do
      it "returns a link to the previous step" do
        params[:question_number] = "1"
        session[:follow_up_changes_start_page] = "0"

        expect(
          helper.health_question_backlink_path(consent_form, health_answer)
        ).to eq previous_health_question_wizard_path
      end
    end
  end

  describe "#backlink_path" do
    let(:consent_form) do
      create(:consent_form, :with_health_answers_asthma_branching)
    end
    let(:health_answer) { consent_form.health_answers.first }
    let(:final_wizard_path) { "final_wizard_path" }
    let(:previous_wizard_path) { "previous_wizard_path" }

    before do
      allow(helper).to receive(:wizard_path).with(
        Wicked::FINISH_STEP
      ).and_return(final_wizard_path)

      allow(helper).to receive(:previous_wizard_path).and_return(
        previous_wizard_path
      )
    end

    context "when skip_to_confirm is not set" do
      it "returns a link to the previous step" do
        expect(helper.backlink_path).to eq previous_wizard_path
      end
    end

    context "when skip_to_confirm set" do
      it "returns a link to the finish step" do
        params[:skip_to_confirm] = "true"

        expect(helper.backlink_path).to eq final_wizard_path
      end
    end
  end
end
