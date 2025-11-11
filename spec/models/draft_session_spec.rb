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

  let(:existing_programmes) do
    [CachedProgramme.menacwy, CachedProgramme.td_ipv]
  end
  let(:new_programme) { CachedProgramme.hpv }

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

  describe "#write_to!" do
    subject(:write_to!) { draft_session.write_to!(session) }

    it "adds the sessions to the programme" do
      expect { write_to! }.to change { session.programme_types.size }.by(1)

      expect(session.programmes).to contain_exactly(
        *existing_programmes,
        new_programme
      )
    end
  end

  describe "#create_location_programme_year_groups!" do
    subject(:create_location_programme_year_groups!) do
      draft_session.create_location_programme_year_groups!
    end

    before do
      draft_session.write_to!(session)
      session.save!
    end

    it "creates appropriate programme year groups" do
      location = session.location

      expect { create_location_programme_year_groups! }.to change {
        location.location_programme_year_groups.count
      }.by(new_programme.default_year_groups.count)

      expect(session.programme_year_groups[new_programme]).to eq(
        new_programme.default_year_groups
      )
    end
  end

  describe "#year_groups" do
    subject(:year_groups) { draft_session.year_groups }

    it { should all(be_a(Integer)) }
  end
end
