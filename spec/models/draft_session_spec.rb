# frozen_string_literal: true

describe DraftSession do
  subject(:draft_session) do
    instance = described_class.new(request_session:, current_user:)
    instance.read_from!(session)
    instance.assign_attributes(attributes)
    instance
  end

  let(:team) do
    create(
      :team,
      :with_one_nurse,
      programmes: existing_programmes + [new_programme]
    )
  end

  let(:request_session) { {} }
  let(:current_user) { team.users.first }

  let(:existing_programmes) { [Programme.menacwy, Programme.td_ipv] }
  let(:new_programme) { Programme.hpv }

  let(:session) { create(:session, team:, programmes: existing_programmes) }
  let(:programme_types) do
    existing_programmes.map(&:type) + [new_programme.type]
  end

  let(:attributes) { { programme_types:, wizard_step: :programmes } }

  describe "validations" do
    it { should be_valid }

    context "when attempting to remove a programme" do
      let(:programme_types) { [existing_programmes.first.id] }

      it "is invalid" do
        expect(draft_session.save(context: :update)).to be(false)
        expect(draft_session.errors[:programme_types]).to include(
          "You cannot remove a programme from the session once it has been added"
        )
      end
    end
  end

  describe "#year_groups" do
    subject(:year_groups) { draft_session.year_groups }

    it { should all(be_a(Integer)) }
  end
end
