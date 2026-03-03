# frozen_string_literal: true

describe AppConsentParentSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(consent) }
  let(:parent) do
    create(
      :parent,
      full_name: "Jane Doe",
      email: "jane@example.com",
      phone: "07700900123"
    )
  end
  let(:patient) { create(:patient) }
  let(:parent_relationship) do
    create(:parent_relationship, :mother, parent:, patient:)
  end

  context "when consent has parent details stored" do
    let(:consent) do
      create(
        :consent,
        patient:,
        parent:,
        parent_full_name: "Stored Name",
        parent_email: "stored@example.com",
        parent_phone: "07700900456",
        parent_phone_receive_updates: true,
        parent_relationship_type: "father"
      )
    end

    it "displays the stored parent details" do
      expect(rendered).to have_content("Stored Name")
      expect(rendered).to have_content("stored@example.com")
      expect(rendered).to have_content("07700 900456")
      expect(rendered).to have_content("Dad")
    end
  end

  context "when consent has no parent details stored (legacy consent)" do
    before { parent_relationship }

    let(:consent) do
      create(
        :consent,
        patient: patient.reload,
        parent:,
        parent_full_name: nil,
        parent_email: nil,
        parent_phone: nil,
        parent_phone_receive_updates: nil,
        parent_relationship_type: nil
      )
    end

    it "falls back to parent object details" do
      expect(rendered).to have_content("Jane Doe")
      expect(rendered).to have_content("jane@example.com")
      expect(rendered).to have_content("07700 900123")
      expect(rendered).to have_content("Mum")
    end
  end
end
