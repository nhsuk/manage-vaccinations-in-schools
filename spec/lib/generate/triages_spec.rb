# frozen_string_literal: true

describe Generate::Triages do
  let(:programme) { Programme.hpv&.first || create(:programme, :hpv) }
  let(:organisation) { create(:organisation, programmes: [programme]) }
  let(:user) { create(:user, organisation:) }
  let(:patient) do
    create(
      :patient,
      :consent_given_triage_needed,
      programmes: [programme],
      session:
    )
  end
  let(:session) { create(:session, organisation:, programmes: [programme]) }

  describe "ready to vaccinate triages" do
    it "creates one consent response" do
      user
      patient

      described_class.call(
        organisation:,
        programme:,
        session:,
        ready_to_vaccinate: 1,
        do_not_vaccinate: 0
      )
      expect(Triage.ready_to_vaccinate.count).to eq 1
    end
  end

  describe "do not vaccinate triages" do
    it "creates one consent response" do
      user
      patient

      described_class.call(
        organisation:,
        programme:,
        session:,
        ready_to_vaccinate: 0,
        do_not_vaccinate: 1
      )
      expect(Triage.do_not_vaccinate.count).to eq 1
    end
  end
end
