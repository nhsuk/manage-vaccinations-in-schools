# frozen_string_literal: true

describe SchoolTeamContactForm do
  let(:session) { {} }
  let(:form) { described_class.new(request_session: session) }

  describe "#wizard_steps" do
    it "returns school and contact_details" do
      expect(form.wizard_steps).to eq(%i[school contact_details])
    end
  end

  describe "validations" do
    context "on school step" do
      before { form.wizard_step = :school }

      context "when school_id is blank" do
        it "is invalid" do
          form.school_id = nil
          expect(form).not_to be_valid(:update)
        end

        it "adds a presence error on school_id" do
          form.school_id = nil
          form.valid?(:update)
          expect(form.errors[:school_id]).to include("Select a school")
        end
      end

      context "when school_id is for a valid school" do
        let(:team) { create(:team) }
        let!(:school) { create(:school, team:, name: "Test School") }

        it "is valid" do
          form.school_id = school.id
          expect(form).to be_valid
        end
      end
    end
  end

  describe "#school" do
    let(:team) { create(:team) }
    let!(:school) { create(:school, team:, name: "Test School") }

    it "returns the school when school_id is set" do
      form.school_id = school.id
      expect(form.school).to eq(school)
    end

    it "returns nil when school_id is blank" do
      form.school_id = nil
      expect(form.school).to be_nil
    end
  end
end
