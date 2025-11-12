# frozen_string_literal: true

describe ImportantNoticeGeneratorJob do
  include ActiveJob::TestHelper

  let(:team_a) { create(:team) }
  let(:team_b) { create(:team) }
  let(:session_a) { create(:session, team: team_a, programmes:) }
  let(:session_b) { create(:session, team: team_b, programmes:) }
  let(:programmes) { [CachedProgramme.flu] }
  let(:patient) { create(:patient) }

  before do
    create(:patient_location, patient:, session: session_a)
    create(:patient_location, patient:, session: session_b)
  end

  describe "#perform" do
    subject(:perform) { described_class.new.perform(patient.id) }

    context "when patient exists in multiple teams" do
      context "deceased" do
        before do
          patient.update_columns(
            # if we use update! the jobs gets called automatically
            date_of_death: Time.current,
            date_of_death_recorded_at: Time.current
          )
        end

        it "creates deceased notices for all associated teams" do
          expect { perform }.to change { team_a.important_notices.count }.by(
            1
          ).and change { team_b.important_notices.count }.by(1)

          expect(team_a.important_notices.first.type).to eq("deceased")
          expect(team_a.important_notices.first.message).to eq(
            "Record updated with child’s date of death"
          )

          expect { described_class.new.perform(patient.id) }.to not_change(
            team_a.important_notices,
            :count
          ).and not_change(team_b.important_notices, :count)
        end
      end

      context "restricted" do
        before { patient.update_column(:restricted_at, Time.current) }

        it "creates restricted notices for all associated teams" do
          expect { perform }.to change(ImportantNotice, :count).by(2)

          notices = patient.important_notices.where(type: :restricted)
          expect(notices.pluck(:team_id)).to contain_exactly(
            team_a.id,
            team_b.id
          )
          expect(notices.first.can_dismiss?).to be true
          expect(notices.first.message).to eq("Record flagged as sensitive")
        end

        context "patient is no longer restricted" do
          before do
            patient.update!(restricted_at: Time.current)
            patient.update_column(:restricted_at, nil)
          end

          it "dismisses existing restricted notices" do
            expect { perform }.to change {
              ImportantNotice
                .active(team: team_a)
                .where(patient:, type: :restricted)
                .count
            }.from(1).to(0)
          end
        end
      end

      context "invalidated" do
        before { patient.update_column(:invalidated_at, Time.current) }

        it "creates invalidated notices for all associated teams" do
          expect { perform }.to change(ImportantNotice, :count).by(2)

          notices = patient.important_notices.where(type: :invalidated)
          expect(notices.pluck(:team_id)).to contain_exactly(
            team_a.id,
            team_b.id
          )
          expect(notices.first.can_dismiss?).to be false
          expect(notices.first.message).to eq("Record flagged as invalid")
        end

        context "patient is no longer invalidated" do
          before do
            patient.update!(invalidated_at: Time.current)
            patient.update_column(:invalidated_at, nil)
          end

          it "dismisses existing invalidated notices" do
            expect { perform }.to change {
              ImportantNotice
                .active(team: team_a)
                .where(patient:, type: :invalidated)
                .count
            }.from(1).to(0)
          end
        end
      end

      context "gillick_no_notify" do
        it "creates notice only for vaccination team" do
          expect {
            create(
              :vaccination_record,
              patient: patient,
              team: team_a,
              notify_parents: false,
              programme: programmes.first,
              session: session_a
            )
          }.to have_enqueued_job(described_class).with(patient.id)

          perform_enqueued_jobs

          expect(team_a.important_notices.count).to eq(1)
          expect(team_b.important_notices.count).to eq(0)

          expect(team_a.important_notices.first.type).to eq("gillick_no_notify")
          expect(team_a.important_notices.first.can_dismiss?).to be true
        end
      end
    end
  end
end
