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
    let(:programmes) { [Programme.hpv] }
    let(:disease_types) { programmes.flat_map(&:disease_types).uniq.presence }
    let(:programme_types) { programmes.map(&:type) }
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
        expect(consent_notification.programme_types).to eq(programme_types)
        expect(consent_notification.patient).to eq(patient)
        expect(consent_notification.sent_at).to eq(today)
      end

      it "enqueues an email per parent" do
        expect { create_and_send! }.to have_delivered_email(
          :consent_school_request_hpv
        ).with(
          disease_types:,
          parent: parents.first,
          patient:,
          programme_types:,
          session:,
          sent_by: current_user
        ).and have_delivered_email(:consent_school_request_hpv).with(
                disease_types:,
                parent: parents.second,
                patient:,
                programme_types:,
                session:,
                sent_by: current_user
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_delivered_sms(
          :consent_school_request
        ).with(
          disease_types:,
          parent: parents.first,
          patient:,
          programme_types:,
          session:,
          sent_by: current_user
        ).and have_delivered_sms(:consent_school_request).with(
                disease_types:,
                parent: parents.second,
                patient:,
                programme_types:,
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
            disease_types:,
            parent:,
            patient:,
            programme_types:,
            session:,
            sent_by: current_user
          )
        end
      end

      context "with Td/IPV and MenACWY programmes" do
        let(:programmes) { [Programme.menacwy, Programme.td_ipv] }

        it "enqueues an email per parent" do
          expect { create_and_send! }.to have_delivered_email(
            :consent_school_request_doubles
          ).twice
        end

        it "enqueues an sms per parent" do
          expect { create_and_send! }.to have_delivered_sms(
            :consent_school_request
          ).twice
        end
      end

      context "with the Flu programme" do
        let(:programmes) { [Programme.flu] }

        it "enqueues an email per parent" do
          expect { create_and_send! }.to have_delivered_email(
            :consent_school_request_flu
          ).twice
        end

        it "enqueues an sms per parent" do
          expect { create_and_send! }.to have_delivered_sms(
            :consent_school_request
          ).twice
        end
      end

      context "with an MMR programme" do
        let(:programmes) { [Programme.mmr] }

        context "when patient is eligible for MMRV" do
          before do
            allow(patient).to receive(:eligible_for_mmrv?).and_return(true)
          end

          it "enqueues an email per parent" do
            expect { create_and_send! }.to have_delivered_email(
              :consent_school_request_mmrv
            ).twice
          end

          it "enqueues an sms per parent" do
            expect { create_and_send! }.to have_delivered_sms(
              :consent_school_request_mmr
            ).twice
          end

          context "when session is set to send outbreak requests" do
            let(:session) do
              create(:session, location:, programmes:, team:, outbreak: true)
            end

            it "enqueues an outbreak email per parent" do
              expect { create_and_send! }.to have_delivered_email(
                :consent_school_request_mmrv_outbreak
              ).twice
            end

            it "enqueues an sms" do
              expect { create_and_send! }.to have_delivered_sms(
                :consent_school_request_mmr
              ).twice
            end
          end
        end

        context "when patient is not eligible for MMRV" do
          before do
            allow(patient).to receive(:eligible_for_mmrv?).and_return(false)
          end

          it "enqueues an email per parent" do
            expect { create_and_send! }.to have_delivered_email(
              :consent_school_request_mmr
            ).twice
          end

          it "enqueues an sms" do
            expect { create_and_send! }.to have_delivered_sms(
              :consent_school_request_mmr
            ).twice
          end

          context "when session is set to send outbreak style requests" do
            let(:session) do
              create(:session, location:, programmes:, team:, outbreak: true)
            end

            it "enqueues an outbreak email per parent" do
              expect { create_and_send! }.to have_delivered_email(
                :consent_school_request_mmr_outbreak
              ).twice
            end

            it "enqueues an sms" do
              expect { create_and_send! }.to have_delivered_sms(
                :consent_school_request_mmr
              ).twice
            end
          end
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
          disease_types:,
          parent: parents.first,
          patient:,
          programme_types:,
          session:,
          sent_by: current_user
        ).and have_delivered_email(:consent_clinic_request).with(
                disease_types:,
                parent: parents.second,
                patient:,
                programme_types:,
                session:,
                sent_by: current_user
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_delivered_sms(
          :consent_clinic_request
        ).with(
          disease_types:,
          parent: parents.first,
          patient:,
          programme_types:,
          session:,
          sent_by: current_user
        ).and have_delivered_sms(:consent_clinic_request).with(
                disease_types:,
                parent: parents.second,
                patient:,
                programme_types:,
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
            disease_types:,
            parent:,
            patient:,
            programme_types:,
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

      it "enqueues an email per parent with the correct args" do
        expect { create_and_send! }.to have_delivered_email(
          :consent_school_initial_reminder_hpv
        ).with(
          disease_types:,
          parent: parents.first,
          patient:,
          programme_types:,
          session:,
          sent_by: current_user
        ).and have_delivered_email(:consent_school_initial_reminder_hpv).with(
                disease_types:,
                parent: parents.second,
                patient:,
                programme_types:,
                session:,
                sent_by: current_user
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_delivered_sms(
          :consent_school_reminder
        ).with(
          disease_types:,
          parent: parents.first,
          patient:,
          programme_types:,
          session:,
          sent_by: current_user
        ).and have_delivered_sms(:consent_school_reminder).with(
                disease_types:,
                parent: parents.second,
                patient:,
                programme_types:,
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
            disease_types:,
            parent:,
            patient:,
            programme_types:,
            session:,
            sent_by: current_user
          )
        end
      end

      context "with Td/IPV and MenACWY programmes" do
        let(:programmes) { [Programme.menacwy, Programme.td_ipv] }

        it "enqueues an email per parent" do
          expect { create_and_send! }.to have_delivered_email(
            :consent_school_initial_reminder_doubles
          ).twice
        end

        it "enqueues an sms per parent" do
          expect { create_and_send! }.to have_delivered_sms(
            :consent_school_reminder
          ).twice
        end
      end

      context "with the Flu programme" do
        let(:programmes) { [Programme.flu] }

        it "enqueues an email per parent" do
          expect { create_and_send! }.to have_delivered_email(
            :consent_school_initial_reminder_flu
          ).twice
        end

        it "enqueues an sms per parent" do
          expect { create_and_send! }.to have_delivered_sms(
            :consent_school_reminder
          ).twice
        end
      end

      context "with an MMR programme" do
        let(:programmes) { [Programme.mmr] }

        it "enqueues an email" do
          expect { create_and_send! }.to have_delivered_email(
            :consent_school_initial_reminder_mmr
          ).twice
        end

        it "enqueues an sms" do
          expect { create_and_send! }.to have_delivered_sms(
            :consent_school_reminder
          ).twice
        end

        context "with a session that is set to send outbreak style requests" do
          let(:session) do
            create(:session, location:, programmes:, team:, outbreak: true)
          end

          it "enqueues an email" do
            expect { create_and_send! }.to have_delivered_email(
              :consent_school_initial_reminder_mmr
            ).twice
          end

          it "enqueues an sms" do
            expect { create_and_send! }.to have_delivered_sms(
              :consent_school_reminder
            ).twice
          end
        end

        context "and a patient that is eligible for mmrv" do
          before do
            allow(patient).to receive(:eligible_for_mmrv?).and_return(true)
          end

          it "enqueues an email" do
            expect { create_and_send! }.to have_delivered_email(
              :consent_school_initial_reminder_mmrv
            ).twice
          end

          it "enqueues an sms" do
            expect { create_and_send! }.to have_delivered_sms(
              :consent_school_reminder
            ).twice
          end

          context "with a session that is set to send outbreak style requests" do
            let(:session) do
              create(:session, location:, programmes:, team:, outbreak: true)
            end

            it "enqueues an email" do
              expect { create_and_send! }.to have_delivered_email(
                :consent_school_initial_reminder_mmrv
              ).twice
            end

            it "enqueues an sms" do
              expect { create_and_send! }.to have_delivered_sms(
                :consent_school_reminder
              ).twice
            end
          end
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
          disease_types:,
          parent: parents.first,
          patient:,
          programme_types:,
          session:,
          sent_by: current_user
        ).and have_delivered_email(
                :consent_school_subsequent_reminder_hpv
              ).with(
                disease_types:,
                parent: parents.second,
                patient:,
                programme_types:,
                session:,
                sent_by: current_user
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_delivered_sms(
          :consent_school_reminder
        ).with(
          disease_types:,
          parent: parents.first,
          patient:,
          programme_types:,
          session:,
          sent_by: current_user
        ).and have_delivered_sms(:consent_school_reminder).with(
                disease_types:,
                parent: parents.second,
                patient:,
                programme_types:,
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
            disease_types:,
            parent:,
            patient:,
            programme_types:,
            session:,
            sent_by: current_user
          )
        end
      end

      context "with Td/IPV and MenACWY programmes" do
        let(:programmes) { [Programme.menacwy, Programme.td_ipv] }

        it "enqueues an email per parent" do
          expect { create_and_send! }.to have_delivered_email(
            :consent_school_subsequent_reminder_doubles
          ).twice
        end

        it "enqueues an sms per parent" do
          expect { create_and_send! }.to have_delivered_sms(
            :consent_school_reminder
          ).twice
        end
      end

      context "with the Flu programme" do
        let(:programmes) { [Programme.flu] }

        it "enqueues an email per parent" do
          expect { create_and_send! }.to have_delivered_email(
            :consent_school_subsequent_reminder_flu
          ).twice
        end

        it "enqueues an sms per parent" do
          expect { create_and_send! }.to have_delivered_sms(
            :consent_school_reminder
          ).twice
        end
      end

      context "with an MMR programme" do
        let(:programmes) { [Programme.mmr] }

        it "enqueues an email" do
          expect { create_and_send! }.to have_delivered_email(
            :consent_school_subsequent_reminder_mmr
          ).twice
        end

        it "enqueues an sms" do
          expect { create_and_send! }.to have_delivered_sms(
            :consent_school_reminder
          ).twice
        end

        context "with a session that is set to send outbreak style requests" do
          let(:session) do
            create(:session, location:, programmes:, team:, outbreak: true)
          end

          it "enqueues an email" do
            expect { create_and_send! }.to have_delivered_email(
              :consent_school_subsequent_reminder_mmr
            ).twice
          end

          it "enqueues an sms" do
            expect { create_and_send! }.to have_delivered_sms(
              :consent_school_reminder
            ).twice
          end
        end

        context "and a patient that is eligible for mmrv" do
          before do
            allow(patient).to receive(:eligible_for_mmrv?).and_return(true)
          end

          it "enqueues an email" do
            expect { create_and_send! }.to have_delivered_email(
              :consent_school_subsequent_reminder_mmrv
            ).twice
          end

          it "enqueues an sms" do
            expect { create_and_send! }.to have_delivered_sms(
              :consent_school_reminder
            ).twice
          end

          context "with a session that is set to send outbreak style requests" do
            let(:session) do
              create(:session, location:, programmes:, team:, outbreak: true)
            end

            it "enqueues an email" do
              expect { create_and_send! }.to have_delivered_email(
                :consent_school_subsequent_reminder_mmrv
              ).twice
            end

            it "enqueues an sms" do
              expect { create_and_send! }.to have_delivered_sms(
                :consent_school_reminder
              ).twice
            end
          end
        end
      end
    end
  end
end
