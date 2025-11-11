# frozen_string_literal: true

describe HealthAnswersDeduplicator do
  subject(:health_answers) { described_class.call(vaccines:) }

  let(:vaccines) { Vaccine.where_programme(programmes) }

  context "with doubles programmes" do
    let(:programmes) { [CachedProgramme.menacwy, CachedProgramme.td_ipv] }

    it "generates the correct health answers" do
      expect(health_answers.count).to eq(6)

      expect(health_answers[0].question).to eq(
        "Does your child have a bleeding disorder or another medical condition they receive treatment for?"
      )
      expect(health_answers[0].next_question).to eq(1)
      expect(health_answers[0].follow_up_question).to be_nil

      expect(health_answers[1].question).to eq(
        "Does your child have any severe allergies?"
      )
      expect(health_answers[1].next_question).to eq(2)
      expect(health_answers[1].follow_up_question).to be_nil

      expect(health_answers[2].question).to eq(
        "Has your child ever had a severe reaction to any medicines, including vaccines?"
      )
      expect(health_answers[2].next_question).to eq(3)
      expect(health_answers[2].follow_up_question).to be_nil

      expect(health_answers[3].question).to eq(
        "Does your child need extra support during vaccination sessions?"
      )
      expect(health_answers[3].next_question).to eq(4)
      expect(health_answers[3].follow_up_question).to be_nil

      expect(health_answers[4].question).to eq(
        "Has your child had a meningitis (MenACWY) vaccination in the last 5 years?"
      )
      expect(health_answers[4].next_question).to eq(5)
      expect(health_answers[4].follow_up_question).to be_nil

      expect(health_answers[5].question).to eq(
        "Has your child had a tetanus, diphtheria and polio vaccination in the last 5 years?"
      )
      expect(health_answers[5].next_question).to be_nil
      expect(health_answers[5].follow_up_question).to be_nil
    end
  end

  context "with a flu programme" do
    let(:programmes) { [CachedProgramme.flu] }

    it "generates the correct health answers" do
      expect(health_answers.count).to eq(11)

      expect(health_answers[0].question).to eq(
        "Has your child been diagnosed with asthma?"
      )
      expect(health_answers[0].next_question).to eq(3)
      expect(health_answers[0].follow_up_question).to eq(1)

      expect(health_answers[1].question).to eq(
        "Have they taken oral steroids in the last 2 weeks?"
      )
      expect(health_answers[1].next_question).to eq(2)
      expect(health_answers[1].follow_up_question).to be_nil

      expect(health_answers[2].question).to eq(
        "Have they been admitted to intensive care for their asthma?"
      )
      expect(health_answers[2].next_question).to eq(3)
      expect(health_answers[2].follow_up_question).to be_nil

      expect(health_answers[3].question).to eq(
        "Does your child have a disease or treatment that severely affects their immune system?"
      )
      expect(health_answers[3].next_question).to eq(4)
      expect(health_answers[3].follow_up_question).to be_nil

      expect(health_answers[4].question).to eq(
        "Is anyone in your household currently having treatment that severely affects their immune system?"
      )
      expect(health_answers[4].next_question).to eq(5)
      expect(health_answers[4].follow_up_question).to be_nil

      expect(health_answers[5].question).to eq(
        "Has your child ever been admitted to intensive care due to an allergic reaction to egg?"
      )
      expect(health_answers[5].next_question).to eq(6)
      expect(health_answers[5].follow_up_question).to be_nil

      expect(health_answers[6].question).to eq(
        "Does your child have any allergies to medication?"
      )
      expect(health_answers[6].next_question).to eq(7)
      expect(health_answers[6].follow_up_question).to be_nil

      expect(health_answers[7].question).to eq(
        "Has your child ever had a reaction to previous vaccinations?"
      )
      expect(health_answers[7].next_question).to eq(8)
      expect(health_answers[7].follow_up_question).to be_nil

      expect(health_answers[8].question).to eq(
        "Does you child take regular aspirin?"
      )
      expect(health_answers[8].next_question).to eq(9)
      expect(health_answers[8].follow_up_question).to be_nil

      expect(health_answers[9].question).to eq(
        "Has your child had a flu vaccination in the last 5 months?"
      )
      expect(health_answers[9].next_question).to eq(10)
      expect(health_answers[9].follow_up_question).to be_nil

      expect(health_answers[10].question).to eq(
        "Does your child have a bleeding disorder or another medical condition they receive treatment for?"
      )
      expect(health_answers[10].next_question).to be_nil
      expect(health_answers[10].follow_up_question).to be_nil
    end
  end
end
