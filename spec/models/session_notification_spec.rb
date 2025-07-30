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

    let(:parents) { create_list(:parent, 2) }
    let(:patient) { create(:patient, parents:, year_group: 10) }
    let(:programme) { create(:programme, :td_ipv) }
    let(:programmes) { [programme] }
    let(:organisation) { create(:organisation, programmes:) }
    let(:location) { create(:school, organisation:) }
    let(:session) { create(:session, location:, programmes:, organisation:) }
    let(:session_date) { session.dates.min }
    let(:patient_session) { create(:patient_session, patient:, session:) }
    let(:current_user) { create(:user) }

    before { patient_session.patient.strict_loading!(false) }

    context "with a school reminder" do
      let(:type) { :school_reminder }

      let(:parent) { parents.first }

      before do
        create(:consent, :given, patient:, parent:, programme:)
        create(:patient_consent_status, :given, patient:, programme:)
      end

      it "creates a record" do
        expect { create_and_send! }.to change(described_class, :count).by(1)

        session_notification = described_class.last
        expect(session_notification).to be_school_reminder
        expect(session_notification.session).to eq(session)
        expect(session_notification.patient).to eq(patient)
        expect(session_notification.sent_at).to eq(today)
      end

      it "enqueues an email per parent who gave consent" do
        expect { create_and_send! }.to have_delivered_email(
          :session_school_reminder
        ).with(parent:, patient:, programmes:, session:, sent_by: current_user)
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_delivered_sms(
          :session_school_reminder
        ).with(parent:, patient:, programmes:, session:, sent_by: current_user)
      end

      context "when parent doesn't want to receive updates by text" do
        before { parents.each { it.update!(phone_receive_updates: false) } }

        it "doesn't enqueues a text" do
          expect { create_and_send! }.not_to have_delivered_sms
        end
      end

      context "with multiple programmes but only one eligible for vaccination" do
        let(:consented_programmes) { [programme] }

        # No consent for MenACWY
        let(:programmes) do
          consented_programmes + [create(:programme, :menacwy)]
        end

        it "enqueues an email per parent who gave consent" do
          expect { create_and_send! }.to have_delivered_email(
            :session_school_reminder
          ).with(
            parent:,
            patient:,
            programmes: consented_programmes,
            session:,
            sent_by: current_user
          )
        end

        it "enqueues a text per parent" do
          expect { create_and_send! }.to have_delivered_sms(
            :session_school_reminder
          ).with(
            parent:,
            patient:,
            programmes: consented_programmes,
            session:,
            sent_by: current_user
          )
        end
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
        expect(session_notification.sent_at).to eq(today)
      end

      it "enqueues an email per parent" do
        expect { create_and_send! }.to have_delivered_email(
          :session_clinic_initial_invitation
        ).with(
          parent: parents.first,
          patient:,
          programmes:,
          session:,
          sent_by: current_user
        ).and have_delivered_email(:session_clinic_initial_invitation).with(
                parent: parents.second,
                patient:,
                programmes:,
                session:,
                sent_by: current_user
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_delivered_sms(
          :session_clinic_initial_invitation
        ).with(
          parent: parents.first,
          patient:,
          programmes:,
          session:,
          sent_by: current_user
        ).and have_delivered_sms(:session_clinic_initial_invitation).with(
                parent: parents.second,
                patient:,
                programmes:,
                session:,
                sent_by: current_user
              )
      end

      context "when the organisation is Coventry & Warwickshire Partnership NHS Trust (CWPT)" do
        let(:organisation) do
          create(:organisation, ods_code: "RYG", programmes:)
        end

        it "enqueues an email using the CWPT-specific template" do
          expect { create_and_send! }.to have_delivered_email(
            :session_clinic_initial_invitation_ryg
          ).with(
            parent: parents.first,
            patient: patient,
            programmes:,
            session: session,
            sent_by: current_user
          )
        end

        it "enqueues an SMS using the CWPT-specific template" do
          expect { create_and_send! }.to have_delivered_sms(
            :session_clinic_initial_invitation_ryg
          ).with(
            parent: parents.first,
            patient: patient,
            programmes:,
            session: session,
            sent_by: current_user
          )
        end
      end

      context "when parent doesn't want to receive updates by text" do
        let(:parent) { parents.first }

        before { parent.update!(phone_receive_updates: false) }

        it "still enqueues a text" do
          expect { create_and_send! }.to have_delivered_sms(
            :session_clinic_initial_invitation
          ).with(
            parent:,
            patient:,
            programmes:,
            session:,
            sent_by: current_user
          )
        end
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
        expect(session_notification.sent_at).to eq(today)
      end

      it "enqueues an email per parent" do
        expect { create_and_send! }.to have_delivered_email(
          :session_clinic_subsequent_invitation
        ).with(
          parent: parents.first,
          patient:,
          programmes:,
          session:,
          sent_by: current_user
        ).and have_delivered_email(:session_clinic_subsequent_invitation).with(
                parent: parents.second,
                patient:,
                programmes:,
                session:,
                sent_by: current_user
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_delivered_sms(
          :session_clinic_subsequent_invitation
        ).with(
          parent: parents.first,
          patient:,
          programmes:,
          session:,
          sent_by: current_user
        ).and have_delivered_sms(:session_clinic_subsequent_invitation).with(
                parent: parents.second,
                patient:,
                programmes:,
                session:,
                sent_by: current_user
              )
      end

      context "when parent doesn't want to receive updates by text" do
        let(:parent) { parents.first }

        before { parent.update!(phone_receive_updates: false) }

        it "still enqueues a text" do
          expect { create_and_send! }.to have_delivered_sms(
            :session_clinic_subsequent_invitation
          ).with(
            parent:,
            patient:,
            programmes:,
            session:,
            sent_by: current_user
          )
        end
      end
    end
  end
end
