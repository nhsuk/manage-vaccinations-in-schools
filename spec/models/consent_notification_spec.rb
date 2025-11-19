# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_notifications
#
#  id              :bigint           not null, primary key
#  programme_types :enum             not null, is an Array
#  sent_at         :datetime         not null
#  type            :integer          not null
#  patient_id      :bigint           not null
#  sent_by_user_id :bigint
#  session_id      :bigint           not null
#
# Indexes
#
#  index_consent_notifications_on_patient_id       (patient_id)
#  index_consent_notifications_on_programme_types  (programme_types) USING gin
#  index_consent_notifications_on_sent_by_user_id  (sent_by_user_id)
#  index_consent_notifications_on_session_id       (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (sent_by_user_id => users.id)
#  fk_rails_...  (session_id => sessions.id)
#
describe ConsentNotification do
  describe "#create_and_send!" do
    subject(:create_and_send!) do
      travel_to(today) do
        described_class.create_and_send!(
          patient:,
          programmes:,
          session:,
          type:,
          current_user:
        )
      end
    end

    let(:today) { Date.new(2024, 1, 1) }

    let(:parents) { create_list(:parent, 2) }
    let(:patient) { create(:patient, parents:, session:) }
    let(:programmes) { [CachedProgramme.hpv] }
    let(:team) { create(:team, programmes:) }
    let(:location) { create(:school, team:) }
    let(:session) { create(:session, location:, programmes:, team:) }
    let(:current_user) { nil }

    context "with a request and a school location" do
      let(:type) { :request }

      it "creates a record" do
        expect { create_and_send! }.to change(described_class, :count).by(1)

        consent_notification = described_class.last
        expect(consent_notification).not_to be_an_automated_reminder
        expect(consent_notification.programmes).to eq(programmes)
        expect(consent_notification.patient).to eq(patient)
        expect(consent_notification.sent_at).to eq(today)
      end

      it "enqueues an email per parent" do
        expect { create_and_send! }.to have_delivered_email(
          :consent_school_request_hpv
        ).with(
          parent: parents.first,
          patient:,
          programmes:,
          session:,
          sent_by: current_user
        ).and have_delivered_email(:consent_school_request_hpv).with(
                parent: parents.second,
                patient:,
                programmes:,
                session:,
                sent_by: current_user
              )
      end

      context "with Td/IPV and MenACWY programmes" do
        let(:programmes) { [CachedProgramme.menacwy, CachedProgramme.td_ipv] }

        it "enqueues an email per parent" do
          expect { create_and_send! }.to have_delivered_email(
            :consent_school_request_doubles
          ).with(
            parent: parents.first,
            patient:,
            programmes:,
            session:,
            sent_by: current_user
          )
        end
      end

      context "with the Flu programme" do
        let(:programmes) { [CachedProgramme.flu] }

        it "enqueues an email per parent" do
          expect { create_and_send! }.to have_delivered_email(
            :consent_school_request_flu
          ).with(
            parent: parents.first,
            patient:,
            programmes:,
            session:,
            sent_by: current_user
          )
        end
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_delivered_sms(
          :consent_school_request
        ).with(
          parent: parents.first,
          patient:,
          programmes:,
          session:,
          sent_by: current_user
        ).and have_delivered_sms(:consent_school_request).with(
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
            :consent_school_request
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

    context "with a request and a clinic location" do
      let(:type) { :request }
      let(:location) { create(:generic_clinic, team:) }

      it "creates a record" do
        expect { create_and_send! }.to change(described_class, :count).by(1)

        consent_notification = described_class.last
        expect(consent_notification).not_to be_an_automated_reminder
        expect(consent_notification.programmes).to eq(programmes)
        expect(consent_notification.patient).to eq(patient)
        expect(consent_notification.sent_at).to eq(today)
      end

      it "enqueues an email per parent" do
        expect { create_and_send! }.to have_delivered_email(
          :consent_clinic_request
        ).with(
          parent: parents.first,
          patient:,
          programmes:,
          session:,
          sent_by: current_user
        ).and have_delivered_email(:consent_clinic_request).with(
                parent: parents.second,
                patient:,
                programmes:,
                session:,
                sent_by: current_user
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_delivered_sms(
          :consent_clinic_request
        ).with(
          parent: parents.first,
          patient:,
          programmes:,
          session:,
          sent_by: current_user
        ).and have_delivered_sms(:consent_clinic_request).with(
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
            :consent_clinic_request
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

    context "with an initial reminder" do
      let(:type) { :initial_reminder }

      it "creates a record" do
        expect { create_and_send! }.to change(described_class, :count).by(1)

        consent_notification = described_class.last
        expect(consent_notification).to be_an_automated_reminder
        expect(consent_notification.programmes).to eq(programmes)
        expect(consent_notification.patient).to eq(patient)
        expect(consent_notification.sent_at).to eq(today)
      end

      it "enqueues an email per parent" do
        expect { create_and_send! }.to have_delivered_email(
          :consent_school_initial_reminder_hpv
        ).with(
          parent: parents.first,
          patient:,
          programmes:,
          session:,
          sent_by: current_user
        ).and have_delivered_email(:consent_school_initial_reminder_hpv).with(
                parent: parents.second,
                patient:,
                programmes:,
                session:,
                sent_by: current_user
              )
      end

      context "with Td/IPV and MenACWY programmes" do
        let(:programmes) { [CachedProgramme.menacwy, CachedProgramme.td_ipv] }

        it "enqueues an email per parent" do
          expect { create_and_send! }.to have_delivered_email(
            :consent_school_initial_reminder_doubles
          ).with(
            parent: parents.first,
            patient:,
            programmes:,
            session:,
            sent_by: current_user
          )
        end
      end

      context "with the Flu programme" do
        let(:programmes) { [CachedProgramme.flu] }

        it "enqueues an email per parent" do
          expect { create_and_send! }.to have_delivered_email(
            :consent_school_initial_reminder_flu
          ).with(
            parent: parents.first,
            patient:,
            programmes:,
            session:,
            sent_by: current_user
          )
        end
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_delivered_sms(
          :consent_school_reminder
        ).with(
          parent: parents.first,
          patient:,
          programmes:,
          session:,
          sent_by: current_user
        ).and have_delivered_sms(:consent_school_reminder).with(
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
            :consent_school_reminder
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

    context "with a subsequent reminder" do
      let(:type) { :subsequent_reminder }

      it "creates a record" do
        expect { create_and_send! }.to change(described_class, :count).by(1)

        consent_notification = described_class.last
        expect(consent_notification).to be_an_automated_reminder
        expect(consent_notification.programmes).to eq(programmes)
        expect(consent_notification.patient).to eq(patient)
        expect(consent_notification.sent_at).to eq(today)
      end

      it "enqueues an email per parent" do
        expect { create_and_send! }.to have_delivered_email(
          :consent_school_subsequent_reminder_hpv
        ).with(
          parent: parents.first,
          patient:,
          programmes:,
          session:,
          sent_by: current_user
        ).and have_delivered_email(
                :consent_school_subsequent_reminder_hpv
              ).with(
                parent: parents.second,
                patient:,
                programmes:,
                session:,
                sent_by: current_user
              )
      end

      context "with Td/IPV and MenACWY programmes" do
        let(:programmes) { [CachedProgramme.menacwy, CachedProgramme.td_ipv] }

        it "enqueues an email per parent" do
          expect { create_and_send! }.to have_delivered_email(
            :consent_school_subsequent_reminder_doubles
          ).with(
            parent: parents.first,
            patient:,
            programmes:,
            session:,
            sent_by: current_user
          )
        end
      end

      context "with the Flu programme" do
        let(:programmes) { [CachedProgramme.flu] }

        it "enqueues an email per parent" do
          expect { create_and_send! }.to have_delivered_email(
            :consent_school_subsequent_reminder_flu
          ).with(
            parent: parents.first,
            patient:,
            programmes:,
            session:,
            sent_by: current_user
          )
        end
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_delivered_sms(
          :consent_school_reminder
        ).with(
          parent: parents.first,
          patient:,
          programmes:,
          session:,
          sent_by: current_user
        ).and have_delivered_sms(:consent_school_reminder).with(
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
            :consent_school_reminder
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
