# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_notifications
#
#  id              :bigint           not null, primary key
#  sent_at         :datetime         not null
#  type            :integer          not null
#  patient_id      :bigint           not null
#  programme_id    :bigint           not null
#  sent_by_user_id :bigint
#  session_id      :bigint           not null
#
# Indexes
#
#  index_consent_notifications_on_patient_id                   (patient_id)
#  index_consent_notifications_on_patient_id_and_programme_id  (patient_id,programme_id)
#  index_consent_notifications_on_programme_id                 (programme_id)
#  index_consent_notifications_on_sent_by_user_id              (sent_by_user_id)
#  index_consent_notifications_on_session_id                   (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (sent_by_user_id => users.id)
#  fk_rails_...  (session_id => sessions.id)
#
describe ConsentNotification do
  describe "#create_and_send!" do
    subject(:create_and_send!) do
      travel_to(today) do
        described_class.create_and_send!(
          patient:,
          programme:,
          session:,
          type:,
          current_user:
        )
      end
    end

    let(:today) { Date.new(2024, 1, 1) }

    let(:parents) { create_list(:parent, 2) }
    let(:patient) { create(:patient, parents:) }
    let(:programme) { create(:programme) }
    let(:organisation) { create(:organisation, programmes: [programme]) }
    let(:location) { create(:location, :school, organisation:) }
    let(:session) do
      create(
        :session,
        location:,
        programme:,
        patients: [patient],
        organisation:
      )
    end
    let(:current_user) { nil }

    context "with a request and a school location" do
      let(:type) { :request }

      it "creates a record" do
        expect { create_and_send! }.to change(described_class, :count).by(1)

        consent_notification = described_class.last
        expect(consent_notification).not_to be_reminder
        expect(consent_notification.programme).to eq(programme)
        expect(consent_notification.patient).to eq(patient)
        expect(consent_notification.sent_at).to be_today
      end

      it "enqueues an email per parent" do
        expect { create_and_send! }.to have_enqueued_mail(
          ConsentMailer,
          :school_request
        ).with(
          params: {
            parent: parents.first,
            patient:,
            programme:,
            session:,
            sent_by: current_user
          },
          args: []
        ).and have_enqueued_mail(ConsentMailer, :school_request).with(
                params: {
                  parent: parents.second,
                  patient:,
                  programme:,
                  session:,
                  sent_by: current_user
                },
                args: []
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_enqueued_text(
          :consent_school_request
        ).with(
          parent: parents.first,
          patient:,
          programme:,
          session:,
          sent_by: current_user
        ).and have_enqueued_text(:consent_school_request).with(
                parent: parents.second,
                patient:,
                programme:,
                session:,
                sent_by: current_user
              )
      end
    end

    context "with a request and a clinic location" do
      let(:type) { :request }
      let(:location) { create(:location, :generic_clinic, organisation:) }

      it "creates a record" do
        expect { create_and_send! }.to change(described_class, :count).by(1)

        consent_notification = described_class.last
        expect(consent_notification).not_to be_reminder
        expect(consent_notification.programme).to eq(programme)
        expect(consent_notification.patient).to eq(patient)
        expect(consent_notification.sent_at).to be_today
      end

      it "enqueues an email per parent" do
        expect { create_and_send! }.to have_enqueued_mail(
          ConsentMailer,
          :clinic_request
        ).with(
          params: {
            parent: parents.first,
            patient:,
            programme:,
            session:,
            sent_by: current_user
          },
          args: []
        ).and have_enqueued_mail(ConsentMailer, :clinic_request).with(
                params: {
                  parent: parents.second,
                  patient:,
                  programme:,
                  session:,
                  sent_by: current_user
                },
                args: []
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_enqueued_text(
          :consent_clinic_request
        ).with(
          parent: parents.first,
          patient:,
          programme:,
          session:,
          sent_by: current_user
        ).and have_enqueued_text(:consent_clinic_request).with(
                parent: parents.second,
                patient:,
                programme:,
                session:,
                sent_by: current_user
              )
      end
    end

    context "with an initial reminder" do
      let(:type) { :initial_reminder }

      it "creates a record" do
        expect { create_and_send! }.to change(described_class, :count).by(1)

        consent_notification = described_class.last
        expect(consent_notification).to be_reminder
        expect(consent_notification.programme).to eq(programme)
        expect(consent_notification.patient).to eq(patient)
        expect(consent_notification.sent_at).to be_today
      end

      it "enqueues an email per parent" do
        expect { create_and_send! }.to have_enqueued_mail(
          ConsentMailer,
          :school_initial_reminder
        ).with(
          params: {
            parent: parents.first,
            patient:,
            programme:,
            session:,
            sent_by: current_user
          },
          args: []
        ).and have_enqueued_mail(ConsentMailer, :school_initial_reminder).with(
                params: {
                  parent: parents.second,
                  patient:,
                  programme:,
                  session:,
                  sent_by: current_user
                },
                args: []
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_enqueued_text(
          :consent_school_reminder
        ).with(
          parent: parents.first,
          patient:,
          programme:,
          session:,
          sent_by: current_user
        ).and have_enqueued_text(:consent_school_reminder).with(
                parent: parents.second,
                patient:,
                programme:,
                session:,
                sent_by: current_user
              )
      end
    end

    context "with a subsequent reminder" do
      let(:type) { :subsequent_reminder }

      it "creates a record" do
        expect { create_and_send! }.to change(described_class, :count).by(1)

        consent_notification = described_class.last
        expect(consent_notification).to be_reminder
        expect(consent_notification.programme).to eq(programme)
        expect(consent_notification.patient).to eq(patient)
        expect(consent_notification.sent_at).to be_today
      end

      it "enqueues an email per parent" do
        expect { create_and_send! }.to have_enqueued_mail(
          ConsentMailer,
          :school_subsequent_reminder
        ).with(
          params: {
            parent: parents.first,
            patient:,
            programme:,
            session:,
            sent_by: current_user
          },
          args: []
        ).and have_enqueued_mail(
                ConsentMailer,
                :school_subsequent_reminder
              ).with(
                params: {
                  parent: parents.second,
                  patient:,
                  programme:,
                  session:,
                  sent_by: current_user
                },
                args: []
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_enqueued_text(
          :consent_school_reminder
        ).with(
          parent: parents.first,
          patient:,
          programme:,
          session:,
          sent_by: current_user
        ).and have_enqueued_text(:consent_school_reminder).with(
                parent: parents.second,
                patient:,
                programme:,
                session:,
                sent_by: current_user
              )
      end
    end
  end
end
