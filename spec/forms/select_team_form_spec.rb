# frozen_string_literal: true

describe SelectTeamForm do
  subject(:form) { described_class.new(cis2_info:) }

  let(:organisation) { create(:organisation) }
  let(:cis2_info) { CIS2Info.new(request_session:) }
  let(:request_session) do
    {
      "cis2_info" => {
        "organisation_code" => organisation.ods_code,
        "workgroups" => [allowed_team.workgroup]
      }
    }
  end
  let(:allowed_team) { create(:team, organisation:) }

  before { create(:team, organisation:) }

  describe "validations" do
    it do
      expect(form).to validate_inclusion_of(:team_id).in_array(
        [allowed_team.id]
      )
    end
  end
end
