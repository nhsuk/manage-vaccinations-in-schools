# frozen_string_literal: true

describe SessionProgrammesForm do
  subject(:form) { described_class.new(session:, programme_ids:) }

  let(:existing_programmes) do
    [create(:programme, :menacwy), create(:programme, :td_ipv)]
  end
  let(:new_programme) { create(:programme, :hpv) }

  let(:session) { create(:session, programmes: existing_programmes) }
  let(:programme_ids) { existing_programmes.map(&:id) + [new_programme.id] }

  describe "validations" do
    it { should be_valid }

    it { should validate_presence_of(:programme_ids) }

    context "when attempting to remove a programme" do
      let(:programme_ids) { [existing_programmes.first.id] }

      it "is invalid" do
        expect(form).to be_invalid
        expect(form.errors[:programme_ids]).to include(
          "You cannot remove a programme from the session once it has been added"
        )
      end
    end
  end

  describe "#save" do
    subject(:save) { form.save }

    it "adds the sessions to the programme" do
      expect { save }.to change { session.programmes.count }.by(1)

      expect(session.programmes).to contain_exactly(
        *existing_programmes,
        new_programme
      )
    end

    it "creates appropriate programme year groups" do
      location = session.location

      expect { save }.to change {
        location.location_programme_year_groups.count
      }.by(new_programme.default_year_groups.count)

      expect(session.programme_year_groups[new_programme]).to eq(
        new_programme.default_year_groups
      )
    end
  end
end
