# frozen_string_literal: true

describe ConsentFormProgramme do
  let(:programme) { Programme.mmr }
  let(:session) { create(:session, programmes: [programme]) }
  let(:consent_form) { create(:consent_form, :given, session:) }
  let(:consent_form_programme) { consent_form.consent_form_programmes.first }

  describe "#vaccines" do
    context "when there are MMR and MMRV vaccines" do
      it "only returns MMR vaccines" do
        expect(consent_form_programme.vaccines).to match_array(
          programme.vaccines
        )
      end
    end
  end
end
