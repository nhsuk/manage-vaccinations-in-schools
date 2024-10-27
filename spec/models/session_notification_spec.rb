# frozen_string_literal: true

# == Schema Information
#
# Table name: session_notifications
#
#  id              :bigint           not null, primary key
#  sent_at         :datetime         not null
#  session_date    :date             not null
#  type            :integer          not null
#  patient_id      :bigint           not null
#  sent_by_user_id :bigint
#  session_id      :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_session_id_session_date_f7f30a3aa3  (patient_id,session_id,session_date)
#  index_session_notifications_on_patient_id             (patient_id)
#  index_session_notifications_on_sent_by_user_id        (sent_by_user_id)
#  index_session_notifications_on_session_id             (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (sent_by_user_id => users.id)
#  fk_rails_...  (session_id => sessions.id)
#
describe SessionNotification do
  describe "#create_and_send!" do
    subject(:create_and_send!) do
      travel_to(today) do
        described_class.create_and_send!(
          patient_session:,
          session_date:,
          type:,
          current_user:
        )
      end
    end

    let(:today) { Date.new(2024, 1, 1) }

    let(:parents) { create_list(:parent, 2, :recorded) }
    let(:patient) { create(:patient, parents:) }
    let(:programme) { create(:programme) }
    let(:team) { create(:team, programmes: [programme]) }
    let(:location) { create(:location, :school, team:) }
    let(:session) { create(:session, location:, programme:, team:) }
    let(:session_date) { session.dates.first.value }
    let(:patient_session) { create(:patient_session, patient:, session:) }
    let(:consent) { create(:consent, :given, :recorded, patient:, programme:) }
    let(:current_user) { create(:user) }

    context "with a school reminder" do
      let(:type) { :school_reminder }

      it "creates a record" do
        expect { create_and_send! }.to change(described_class, :count).by(1)

        session_notification = described_class.last
        expect(session_notification).to be_school_reminder
        expect(session_notification.session).to eq(session)
        expect(session_notification.patient).to eq(patient)
        expect(session_notification.sent_at).to be_today
      end

      it "enqueues an email per parent who gave consent" do
        expect { create_and_send! }.to have_enqueued_mail(
          SessionMailer,
          :school_reminder
        ).with(
          params: {
            consent:,
            patient_session:,
            sent_by: current_user
          },
          args: []
        )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_enqueued_text(
          :session_school_reminder
        ).with(consent:, patient_session:, sent_by: current_user)
      end
    end

    context "with an initial clinic invitation" do
      let(:type) { :clinic_initial_invitation }

      it "creates a record" do
        expect { create_and_send! }.to change(described_class, :count).by(1)

        session_notification = described_class.last
        expect(session_notification).to be_clinic_initial_invitation
        expect(session_notification.session).to eq(session)
        expect(session_notification.patient).to eq(patient)
        expect(session_notification.sent_at).to be_today
      end

      it "enqueues an email per parent" do
        expect { create_and_send! }.to have_enqueued_mail(
          SessionMailer,
          :clinic_initial_invitation
        ).with(
          params: {
            parent: parents.first,
            patient_session:,
            sent_by: current_user
          },
          args: []
        ).and have_enqueued_mail(
                SessionMailer,
                :clinic_initial_invitation
              ).with(
                params: {
                  parent: parents.second,
                  patient_session:,
                  sent_by: current_user
                },
                args: []
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_enqueued_text(
          :session_clinic_initial_invitation
        ).with(
          parent: parents.first,
          patient_session:,
          sent_by: current_user
        ).and have_enqueued_text(:session_clinic_initial_invitation).with(
                parent: parents.second,
                patient_session:,
                sent_by: current_user
              )
      end
    end

    context "with a subsequent clinic invitation" do
      let(:type) { :clinic_subsequent_invitation }

      it "creates a record" do
        expect { create_and_send! }.to change(described_class, :count).by(1)

        session_notification = described_class.last
        expect(session_notification).to be_clinic_subsequent_invitation
        expect(session_notification.session).to eq(session)
        expect(session_notification.patient).to eq(patient)
        expect(session_notification.sent_at).to be_today
      end

      it "enqueues an email per parent" do
        expect { create_and_send! }.to have_enqueued_mail(
          SessionMailer,
          :clinic_subsequent_invitation
        ).with(
          params: {
            parent: parents.first,
            patient_session:,
            sent_by: current_user
          },
          args: []
        ).and have_enqueued_mail(
                SessionMailer,
                :clinic_subsequent_invitation
              ).with(
                params: {
                  parent: parents.second,
                  patient_session:,
                  sent_by: current_user
                },
                args: []
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_enqueued_text(
          :session_clinic_subsequent_invitation
        ).with(
          parent: parents.first,
          patient_session:,
          sent_by: current_user
        ).and have_enqueued_text(:session_clinic_subsequent_invitation).with(
                parent: parents.second,
                patient_session:,
                sent_by: current_user
              )
      end
    end
  end
end
