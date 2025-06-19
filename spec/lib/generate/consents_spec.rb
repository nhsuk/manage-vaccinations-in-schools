# frozen_string_literal: true

describe Generate::Consents do
  let(:programme) { Programme.hpv&.first || create(:programme, :hpv) }
  let(:organisation) { create(:organisation, programmes: [programme]) }
  let(:user) { create(:user, organisation:) }
  let(:session) { create(:session, organisation:, programmes: [programme]) }
  let(:parents) { [create(:parent)] }
  let(:patient) do
    create(:patient, programmes: [programme], session:, parents:)
  end
  let(:config) { {} }

  describe "consents refused" do
    it "generates consents by default" do
      user
      patient

      described_class.call(
        organisation:,
        programme:,
        session:,
        refused: 1,
        given: 0,
        given_needs_triage: 0
      )
      expect(Consent.response_refused.count).to eq 1
      expect(
        Consent.response_refused.count { it.consent_form.present? }
      ).to eq 1
    end
  end

  describe "consents given not needing triage" do
    it "generates consents by default" do
      user
      patient

      described_class.call(
        organisation:,
        programme:,
        session:,
        refused: 0,
        given: 1,
        given_needs_triage: 0
      )

      expect(Consent.response_given.count).to eq 1
      expect(Consent.response_given.count { it.consent_form.present? }).to eq 1
    end
  end

  describe "consents given needing triage" do
    it "generates consents by default" do
      user
      patient

      described_class.call(
        organisation:,
        programme:,
        session:,
        refused: 0,
        given: 0,
        given_needs_triage: 1
      )

      consents_given = Consent.response_given.select(&:requires_triage?)
      expect(consents_given.count).to eq 1
      expect(consents_given.count { it.consent_form.present? }).to eq 1
    end
  end
end
