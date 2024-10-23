# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_notifications
#
#  id           :bigint           not null, primary key
#  sent_at      :datetime         not null
#  type         :integer          not null
#  patient_id   :bigint           not null
#  programme_id :bigint           not null
#
# Indexes
#
#  index_consent_notifications_on_patient_id                   (patient_id)
#  index_consent_notifications_on_patient_id_and_programme_id  (patient_id,programme_id)
#  index_consent_notifications_on_programme_id                 (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (programme_id => programmes.id)
#
describe ConsentNotification do
  describe "#create_and_send!" do
    subject(:create_and_send!) do
      travel_to(today) do
        described_class.create_and_send!(patient:, programme:, session:, type:)
      end
    end

    let(:today) { Date.new(2024, 1, 1) }

    let(:parents) { create_list(:parent, 2) }
    let(:patient) { create(:patient, parents:) }
    let(:programme) { create(:programme) }
    let(:team) { create(:team, programmes: [programme]) }
    let(:location) { create(:location, :school, team:) }
    let(:session) do
      create(:session, location:, programme:, patients: [patient], team:)
    end

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
          :request_for_school
        ).with(
          params: {
            parent: parents.first,
            patient:,
            programme:,
            session:
          },
          args: []
        ).and have_enqueued_mail(ConsentMailer, :request_for_school).with(
                params: {
                  parent: parents.second,
                  patient:,
                  programme:,
                  session:
                },
                args: []
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_enqueued_text(
          :consent_request
        ).with(
          parent: parents.first,
          patient:,
          programme:,
          session:
        ).and have_enqueued_text(:consent_request).with(
                parent: parents.second,
                patient:,
                programme:,
                session:
              )
      end
    end

    context "with a request and a clinic location" do
      let(:type) { :request }
      let(:location) { create(:location, :generic_clinic, team:) }

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
          :request_for_clinic
        ).with(
          params: {
            parent: parents.first,
            patient:,
            programme:,
            session:
          },
          args: []
        ).and have_enqueued_mail(ConsentMailer, :request_for_clinic).with(
                params: {
                  parent: parents.second,
                  patient:,
                  programme:,
                  session:
                },
                args: []
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_enqueued_text(
          :consent_request
        ).with(
          parent: parents.first,
          patient:,
          programme:,
          session:
        ).and have_enqueued_text(:consent_request).with(
                parent: parents.second,
                patient:,
                programme:,
                session:
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
          :initial_reminder
        ).with(
          params: {
            parent: parents.first,
            patient:,
            programme:,
            session:
          },
          args: []
        ).and have_enqueued_mail(ConsentMailer, :initial_reminder).with(
                params: {
                  parent: parents.second,
                  patient:,
                  programme:,
                  session:
                },
                args: []
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_enqueued_text(
          :consent_reminder
        ).with(
          parent: parents.first,
          patient:,
          programme:,
          session:
        ).and have_enqueued_text(:consent_reminder).with(
                parent: parents.second,
                patient:,
                programme:,
                session:
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
          :subsequent_reminder
        ).with(
          params: {
            parent: parents.first,
            patient:,
            programme:,
            session:
          },
          args: []
        ).and have_enqueued_mail(ConsentMailer, :subsequent_reminder).with(
                params: {
                  parent: parents.second,
                  patient:,
                  programme:,
                  session:
                },
                args: []
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_enqueued_text(
          :consent_reminder
        ).with(
          parent: parents.first,
          patient:,
          programme:,
          session:
        ).and have_enqueued_text(:consent_reminder).with(
                parent: parents.second,
                patient:,
                programme:,
                session:
              )
      end
    end
  end
end
