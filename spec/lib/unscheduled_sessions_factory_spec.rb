# frozen_string_literal: true

describe UnscheduledSessionsFactory do
  describe "#call" do
    subject(:call) { described_class.call }

    let(:programmes) { [create(:programme, :hpv)] }
    let(:organisation) { create(:organisation, programmes:) }

    context "with a school that's eligible for the programme" do
      let!(:location) { create(:school, :secondary, organisation:) }

      it "creates missing unscheduled sessions" do
        expect { call }.to change(organisation.sessions, :count).by(1)

        session = organisation.sessions.includes(:location, :programmes).first
        expect(session.location).to eq(location)
        expect(session.programmes).to eq(programmes)
      end
    end

    context "with a generic clinic" do
      let!(:location) { create(:generic_clinic, organisation:) }

      it "creates missing unscheduled sessions" do
        expect { call }.to change(organisation.sessions, :count).by(1)

        session = organisation.sessions.includes(:location, :programmes).first
        expect(session.location).to eq(location)
        expect(session.programmes).to eq(programmes)
      end
    end

    context "with a community clinic" do
      before { create(:community_clinic, organisation:) }

      it "doesn't create any unscheduled sessions" do
        expect { call }.not_to change(organisation.sessions, :count)
      end
    end

    context "with a school that's not eligible for the programme" do
      before { create(:school, :primary, organisation:) }

      it "doesn't create any sessions" do
        expect { call }.not_to change(Session, :count)
      end
    end

    context "when a session already exists" do
      before do
        location = create(:school, :secondary, organisation:)
        create(:session, organisation:, location:, programmes:)
      end

      it "doesn't create any sessions" do
        expect { call }.not_to change(Session, :count)
      end
    end

    context "when a session exists for a different academic year" do
      before do
        location = create(:school, :secondary, organisation:)
        create(
          :session,
          organisation:,
          location:,
          programmes:,
          date: Date.new(2013, 1, 1)
        )
      end

      it "creates the missing unscheduled session" do
        expect { call }.to change(organisation.sessions, :count).by(1)
      end
    end

    context "with an unscheduled session for a location no longer managed by the organisation" do
      let(:location) { create(:school, :secondary) }
      let!(:session) do
        create(:session, :unscheduled, organisation:, location:, programmes:)
      end

      it "destroys the session" do
        expect { call }.to change(Session, :count).by(-1)
        expect { session.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with a scheduled session for a location no longer managed by the organisation" do
      let(:location) { create(:school, :secondary) }

      before do
        create(:session, :scheduled, organisation:, location:, programmes:)
      end

      it "doesn't destroy the session" do
        expect { call }.not_to change(Session, :count)
      end
    end
  end
end
