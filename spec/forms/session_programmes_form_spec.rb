# frozen_string_literal: true

describe SessionProgrammesForm do
  subject(:form) { described_class.new(session:, programme_ids:) }

  let(:programmes) do
    [create(:programme, :menacwy), create(:programme, :td_ipv)]
  end

  let(:session) { create(:session, programmes:) }
  let(:programme_ids) { programmes.map(&:id) }

  it { should be_valid }

  it { should validate_presence_of(:programme_ids) }

  context "when attempting to remove a programme" do
    let(:programme_ids) { [programmes.first.id] }

    it "is invalid" do
      expect(form).to be_invalid
      expect(form.errors[:programme_ids]).to include(
        "You cannot remove a program from the session once it has been added"
      )
    end
  end
end
