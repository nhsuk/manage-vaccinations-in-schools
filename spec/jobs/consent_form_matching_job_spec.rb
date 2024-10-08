# frozen_string_literal: true

describe ConsentFormMatchingJob do
  subject(:perform) { described_class.new.perform(consent_form) }

  let(:session) { create(:session) }
  let(:consent_form) { create(:consent_form, session:) }

  context "with no matching patients" do
    it "doesn't create a consent" do
      expect { perform }.not_to change(Consent, :count)
    end
  end

  context "with one matching patient" do
    let!(:patient) do
      create(
        :patient,
        first_name: consent_form.first_name,
        last_name: consent_form.last_name,
        date_of_birth: consent_form.date_of_birth,
        session:,
        parents: []
      )
    end

    it "creates a consent" do
      expect { perform }.to change(Consent, :count).by(1)
    end

    it "creates a parent" do
      expect { perform }.to change(Parent, :count).by(1)
    end

    it "creates a parent relationship" do
      expect { perform }.to change(ParentRelationship, :count).by(1)

      expect(ParentRelationship.first).to have_attributes(
        patient:,
        parent: Parent.first
      )
    end
  end

  context "with multiple matching patients" do
    before do
      create_list(
        :patient,
        2,
        first_name: consent_form.first_name,
        last_name: consent_form.last_name,
        date_of_birth: consent_form.date_of_birth,
        session:
      )
    end

    it "doesn't create a consent" do
      expect { perform }.not_to change(Consent, :count)
    end
  end
end
