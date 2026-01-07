# frozen_string_literal: true

describe "Programmes" do
  let(:team) { create(:team) }
  let(:nurse) { create(:nurse, teams: [team]) }

  describe "downloading consent form" do
    let(:path) { "/programmes/mmr/consent-form" }

    before do
      sign_in nurse
      2.times { follow_redirect! }
    end

    it "downloads a PDF file with a suitable filename" do
      get path
      expect(response.headers["Content-Type"]).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to include(
        "filename=\"MMR Consent Form.pdf\""
      )
    end
  end
end
