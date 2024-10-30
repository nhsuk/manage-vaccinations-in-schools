# frozen_string_literal: true

describe UnscheduledSessionsFactory do
  describe "#call" do
    subject(:call) { described_class.new.call }

    let(:programme) { create(:programme, :hpv) }
    let(:organisation) { create(:organisation, programmes: [programme]) }

    context "with a school that's eligible for the programme" do
      let!(:location) { create(:location, :secondary, organisation:) }

      it "creates missing unscheduled sessions" do
        expect { call }.to change(organisation.sessions, :count).by(1)

        session = organisation.sessions.first
        expect(session.location).to eq(location)
        expect(session.programmes).to eq([programme])
      end
    end

    context "with a generic clinic" do
      let!(:location) { create(:location, :generic_clinic, organisation:) }

      it "creates missing unscheduled sessions" do
        expect { call }.to change(organisation.sessions, :count).by(1)

        session = organisation.sessions.first
        expect(session.location).to eq(location)
        expect(session.programmes).to eq([programme])
      end
    end

    context "with a community clinic" do
      before { create(:location, :community_clinic, organisation:) }

      it "doesn't create any unscheduled sessions" do
        expect { call }.not_to change(organisation.sessions, :count)
      end
    end

    context "with a school that's not eligible for the programme" do
      before { create(:location, :primary, organisation:) }

      it "doesn't create any sessions" do
        expect { call }.not_to change(Session, :count)
      end
    end

    context "when a session already exists" do
      before do
        location = create(:location, :secondary, organisation:)
        create(:session, organisation:, location:, programme:)
      end

      it "doesn't create any sessions" do
        expect { call }.not_to change(Session, :count)
      end
    end

    context "when a session exists for a different academic year" do
      before do
        location = create(:location, :secondary, organisation:)
        create(
          :session,
          organisation:,
          location:,
          programme:,
          date: Date.new(2013, 1, 1)
        )
      end

      it "creates the missing unscheduled session" do
        expect { call }.to change(organisation.sessions, :count).by(1)
      end
    end

    context "with an unscheduled session for a location no longer managed by the organisation" do
      let(:location) { create(:location, :secondary) }
      let!(:session) do
        create(:session, :unscheduled, organisation:, location:, programme:)
      end

      it "destroys the session" do
        expect { call }.to change(Session, :count).by(-1)
        expect { session.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with a scheduled session for a location no longer managed by the organisation" do
      let(:location) { create(:location, :secondary) }

      before do
        create(:session, :scheduled, organisation:, location:, programme:)
      end

      it "doesn't destroy the session" do
        expect { call }.not_to change(Session, :count)
      end
    end
  end
end
