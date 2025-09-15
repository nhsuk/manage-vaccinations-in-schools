# frozen_string_literal: true

describe AppVaccinationsSummaryTableComponent do
  subject(:rendered) { render_inline(component) }

  let(:request_session) { {} }
  let(:current_user) { build(:user) }

  let(:flu_programme) { create(:programme, :flu, vaccines: []) }
  let(:hpv_programme) { create(:programme, :hpv, vaccines: []) }
  let(:programmes) { [hpv_programme] }
  let(:session) { create(:session, :today, programmes:, team:) }
  let(:team) { create(:team, :with_generic_clinic, programmes:) }

  let(:component) do
    described_class.new(current_user:, session:, request_session:)
  end

  context "with an active vaccine" do
    let(:hpv_vaccine) { create(:vaccine, programme: hpv_programme) }

    it { should have_content(hpv_vaccine.brand) }
  end

  context "with a discontinued vaccine" do
    let(:hpv_vaccine) do
      create(:vaccine, :discontinued, programme: hpv_programme)
    end

    it { should_not have_content(hpv_vaccine.brand) }
  end

  context "bad data exists where we have Flu vaccination records in an HPV session" do
    let(:hpv_vaccine) { create(:vaccine, programme: hpv_programme) }
    let(:flu_vaccine) { create(:vaccine, programme: flu_programme) }
    let(:hpv_batch) { create(:batch, :not_expired, vaccine: hpv_vaccine) }
    let(:flu_batch) { create(:batch, :not_expired, vaccine: flu_vaccine) }

    before do
      create(
        :vaccination_record,
        vaccine: hpv_vaccine,
        batch: hpv_batch,
        session: session,
        programme: hpv_programme,
        performed_by_user: current_user
      )

      create(
        :vaccination_record,
        vaccine: flu_vaccine,
        batch: flu_batch,
        session: session,
        programme: flu_programme,
        performed_by_user: current_user
      )
    end

    it "renders without errors" do
      expect { rendered }.not_to raise_error
    end
  end
end
