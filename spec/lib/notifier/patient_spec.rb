# frozen_string_literal: true

describe Notifier::Patient do
  subject(:notifier) { described_class.new(patient) }

  let(:sent_by) { create(:user) }

  describe "#send_clinic_invitation" do
    subject(:send_clinic_invitation) do
      travel_to(today) do
        notifier.send_clinic_invitation(
          programme_types:,
          team:,
          academic_year:,
          sent_by:
        )
      end
    end

    let(:today) { Date.new(2024, 1, 1) }

    let(:parents) { create_list(:parent, 2) }
    let(:patient) { create(:patient, parents:, year_group: 10) }
    let(:programme) { Programme.td_ipv }
    let(:programmes) { [programme] }
    let(:programme_types) { programmes.map(&:type) }
    let(:team) { create(:team, programmes:) }
    let(:location) { create(:school, team:) }
    let(:academic_year) { AcademicYear.current }

    context "without an invitation already" do
      it "creates a record" do
        expect { send_clinic_invitation }.to change(
          ClinicNotification,
          :count
        ).by(1)

        clinic_notification = ClinicNotification.last
        expect(clinic_notification).to be_initial_invitation
        expect(clinic_notification.team).to eq(team)
        expect(clinic_notification.patient).to eq(patient)
        expect(clinic_notification.sent_at).to eq(today)
      end

      it "enqueues an email per parent" do
        expect { send_clinic_invitation }.to have_delivered_email(
          :clinic_initial_invitation
        ).with(
          parent: parents.first,
          patient:,
          programme_types:,
          team:,
          academic_year:,
          sent_by:
        ).and have_delivered_email(:clinic_initial_invitation).with(
                parent: parents.second,
                patient:,
                programme_types:,
                team:,
                academic_year:,
                sent_by:
              )
      end

      it "enqueues a text per parent" do
        expect { send_clinic_invitation }.to have_delivered_sms(
          :clinic_initial_invitation
        ).with(
          parent: parents.first,
          patient:,
          programme_types:,
          team:,
          academic_year:,
          sent_by:
        ).and have_delivered_sms(:clinic_initial_invitation).with(
                parent: parents.second,
                patient:,
                programme_types:,
                team:,
                academic_year:,
                sent_by:
              )
      end

      context "when the session administers two programmes but the patient only needs one" do
        let(:programmes) { [Programme.flu, Programme.hpv] }

        before do
          create(:vaccination_record, patient:, programme: programmes.first)
          PatientStatusUpdater.call(patient:)
        end

        it "only sends emails for the remaining programme" do
          expect { send_clinic_invitation }.to have_delivered_email(
            :clinic_initial_invitation
          ).with(
            parent: parents.first,
            patient:,
            programme_types: [programmes.second.type],
            team:,
            academic_year:,
            sent_by:
          )
        end

        it "enqueues a text per parent" do
          expect { send_clinic_invitation }.to have_delivered_sms(
            :clinic_initial_invitation
          ).with(
            parent: parents.first,
            patient:,
            programme_types: [programmes.second.type],
            team:,
            academic_year:,
            sent_by:
          )
        end
      end

      context "when the team is Coventry & Warwickshire Partnership NHS Trust (CWPT)" do
        let(:team) { create(:team, ods_code: "RYG", programmes:) }

        it "enqueues an email using the CWPT-specific template" do
          expect { send_clinic_invitation }.to have_delivered_email(
            :clinic_initial_invitation_ryg
          ).with(
            parent: parents.first,
            patient:,
            programme_types:,
            team:,
            academic_year:,
            sent_by:
          )
        end

        it "enqueues an SMS using the CWPT-specific template" do
          expect { send_clinic_invitation }.to have_delivered_sms(
            :clinic_initial_invitation_ryg
          ).with(
            parent: parents.first,
            patient:,
            programme_types:,
            team:,
            academic_year:,
            sent_by:
          )
        end
      end

      context "when the team is Leicestershire Partnership Trust (LPT)" do
        let(:team) { create(:team, ods_code: "RT5", programmes:) }

        it "enqueues an email using the LPT-specific template" do
          expect { send_clinic_invitation }.to have_delivered_email(
            :clinic_initial_invitation_rt5
          ).with(
            parent: parents.first,
            patient:,
            programme_types:,
            team:,
            academic_year:,
            sent_by:
          )
        end

        it "enqueues an SMS using the LPT-specific template" do
          expect { send_clinic_invitation }.to have_delivered_sms(
            :clinic_initial_invitation_rt5
          ).with(
            parent: parents.first,
            patient:,
            programme_types:,
            team:,
            academic_year:,
            sent_by:
          )
        end
      end

      context "when parent doesn't want to receive updates by text" do
        let(:parent) { parents.first }

        before { parent.update!(phone_receive_updates: false) }

        it "still enqueues a text" do
          expect { send_clinic_invitation }.to have_delivered_sms(
            :clinic_initial_invitation
          ).with(
            parent:,
            patient:,
            programme_types:,
            team:,
            academic_year:,
            sent_by:
          )
        end
      end
    end

    context "when already invited" do
      before do
        create(
          :clinic_notification,
          :initial_invitation,
          patient:,
          team:,
          academic_year:,
          programmes:
        )
      end

      it "creates a record" do
        expect { send_clinic_invitation }.to change(
          ClinicNotification,
          :count
        ).by(1)

        clinic_notification = ClinicNotification.last
        expect(clinic_notification).to be_subsequent_invitation
        expect(clinic_notification.team).to eq(team)
        expect(clinic_notification.patient).to eq(patient)
        expect(clinic_notification.sent_at).to eq(today)
      end

      it "enqueues an email per parent" do
        expect { send_clinic_invitation }.to have_delivered_email(
          :clinic_subsequent_invitation
        ).with(
          parent: parents.first,
          patient:,
          programme_types:,
          team:,
          academic_year:,
          sent_by:
        ).and have_delivered_email(:clinic_subsequent_invitation).with(
                parent: parents.second,
                patient:,
                programme_types:,
                team:,
                academic_year:,
                sent_by:
              )
      end

      it "enqueues a text per parent" do
        expect { send_clinic_invitation }.to have_delivered_sms(
          :clinic_subsequent_invitation
        ).with(
          parent: parents.first,
          patient:,
          programme_types:,
          team:,
          academic_year:,
          sent_by:
        ).and have_delivered_sms(:clinic_subsequent_invitation).with(
                parent: parents.second,
                patient:,
                programme_types:,
                team:,
                academic_year:,
                sent_by:
              )
      end

      context "when parent doesn't want to receive updates by text" do
        let(:parent) { parents.first }

        before { parent.update!(phone_receive_updates: false) }

        it "still enqueues a text" do
          expect { send_clinic_invitation }.to have_delivered_sms(
            :clinic_subsequent_invitation
          ).with(
            parent:,
            patient:,
            programme_types:,
            team:,
            academic_year:,
            sent_by:
          )
        end
      end
    end
  end
end
