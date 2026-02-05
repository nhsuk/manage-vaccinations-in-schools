# frozen_string_literal: true

# == Schema Information
#
# Table name: clinic_notifications
#
#  id              :bigint           not null, primary key
#  academic_year   :integer          not null
#  programme_types :enum             not null, is an Array
#  sent_at         :datetime         not null
#  type            :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  patient_id      :bigint           not null
#  sent_by_user_id :bigint
#  team_id         :bigint           not null
#
# Indexes
#
#  index_clinic_notifications_on_patient_id       (patient_id)
#  index_clinic_notifications_on_sent_by_user_id  (sent_by_user_id)
#  index_clinic_notifications_on_team_id          (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (sent_by_user_id => users.id)
#  fk_rails_...  (team_id => teams.id)
#
describe ClinicNotification do
  describe "associations" do
    it { should belong_to(:patient) }
    it { should belong_to(:team) }
  end

  describe "#create_and_send!" do
    subject(:create_and_send!) do
      travel_to(today) do
        described_class.create_and_send!(
          patient:,
          programmes:,
          team:,
          academic_year:,
          type:,
          current_user:
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
    let(:current_user) { create(:user) }

    context "with an initial invitation" do
      let(:type) { :initial_invitation }

      it "creates a record" do
        expect { create_and_send! }.to change(described_class, :count).by(1)

        clinic_notification = described_class.last
        expect(clinic_notification).to be_initial_invitation
        expect(clinic_notification.team).to eq(team)
        expect(clinic_notification.patient).to eq(patient)
        expect(clinic_notification.sent_at).to eq(today)
      end

      it "enqueues an email per parent" do
        expect { create_and_send! }.to have_delivered_email(
          :clinic_initial_invitation
        ).with(
          parent: parents.first,
          patient:,
          programme_types:,
          team:,
          academic_year:,
          sent_by: current_user
        ).and have_delivered_email(:clinic_initial_invitation).with(
                parent: parents.second,
                patient:,
                programme_types:,
                team:,
                academic_year:,
                sent_by: current_user
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_delivered_sms(
          :clinic_initial_invitation
        ).with(
          parent: parents.first,
          patient:,
          programme_types:,
          team:,
          academic_year:,
          sent_by: current_user
        ).and have_delivered_sms(:clinic_initial_invitation).with(
                parent: parents.second,
                patient:,
                programme_types:,
                team:,
                academic_year:,
                sent_by: current_user
              )
      end

      context "when the session administers two programmes but the patient only needs one" do
        let(:programmes) { [Programme.flu, Programme.hpv] }

        before do
          create(:vaccination_record, patient:, programme: programmes.first)
          PatientStatusUpdater.call(patient:)
        end

        it "only sends emails for the remaining programme" do
          expect { create_and_send! }.to have_delivered_email(
            :clinic_initial_invitation
          ).with(
            parent: parents.first,
            patient:,
            programme_types: [programmes.second.type],
            team:,
            academic_year:,
            sent_by: current_user
          )
        end

        it "enqueues a text per parent" do
          expect { create_and_send! }.to have_delivered_sms(
            :clinic_initial_invitation
          ).with(
            parent: parents.first,
            patient:,
            programme_types: [programmes.second.type],
            team:,
            academic_year:,
            sent_by: current_user
          )
        end
      end

      context "when the team is Coventry & Warwickshire Partnership NHS Trust (CWPT)" do
        let(:team) { create(:team, ods_code: "RYG", programmes:) }

        it "enqueues an email using the CWPT-specific template" do
          expect { create_and_send! }.to have_delivered_email(
            :clinic_initial_invitation_ryg
          ).with(
            parent: parents.first,
            patient:,
            programme_types:,
            team:,
            academic_year:,
            sent_by: current_user
          )
        end

        it "enqueues an SMS using the CWPT-specific template" do
          expect { create_and_send! }.to have_delivered_sms(
            :clinic_initial_invitation_ryg
          ).with(
            parent: parents.first,
            patient:,
            programme_types:,
            team:,
            academic_year:,
            sent_by: current_user
          )
        end
      end

      context "when the team is Leicestershire Partnership Trust (LPT)" do
        let(:team) { create(:team, ods_code: "RT5", programmes:) }

        it "enqueues an email using the LPT-specific template" do
          expect { create_and_send! }.to have_delivered_email(
            :clinic_initial_invitation_rt5
          ).with(
            parent: parents.first,
            patient:,
            programme_types:,
            team:,
            academic_year:,
            sent_by: current_user
          )
        end

        it "enqueues an SMS using the LPT-specific template" do
          expect { create_and_send! }.to have_delivered_sms(
            :clinic_initial_invitation_rt5
          ).with(
            parent: parents.first,
            patient:,
            programme_types:,
            team:,
            academic_year:,
            sent_by: current_user
          )
        end
      end

      context "when parent doesn't want to receive updates by text" do
        let(:parent) { parents.first }

        before { parent.update!(phone_receive_updates: false) }

        it "still enqueues a text" do
          expect { create_and_send! }.to have_delivered_sms(
            :clinic_initial_invitation
          ).with(
            parent:,
            patient:,
            programme_types:,
            team:,
            academic_year:,
            sent_by: current_user
          )
        end
      end
    end

    context "with a subsequent clinic invitation" do
      let(:type) { :subsequent_invitation }

      it "creates a record" do
        expect { create_and_send! }.to change(described_class, :count).by(1)

        clinic_notification = described_class.last
        expect(clinic_notification).to be_subsequent_invitation
        expect(clinic_notification.team).to eq(team)
        expect(clinic_notification.patient).to eq(patient)
        expect(clinic_notification.sent_at).to eq(today)
      end

      it "enqueues an email per parent" do
        expect { create_and_send! }.to have_delivered_email(
          :clinic_subsequent_invitation
        ).with(
          parent: parents.first,
          patient:,
          programme_types:,
          team:,
          academic_year:,
          sent_by: current_user
        ).and have_delivered_email(:clinic_subsequent_invitation).with(
                parent: parents.second,
                patient:,
                programme_types:,
                team:,
                academic_year:,
                sent_by: current_user
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_delivered_sms(
          :clinic_subsequent_invitation
        ).with(
          parent: parents.first,
          patient:,
          programme_types:,
          team:,
          academic_year:,
          sent_by: current_user
        ).and have_delivered_sms(:clinic_subsequent_invitation).with(
                parent: parents.second,
                patient:,
                programme_types:,
                team:,
                academic_year:,
                sent_by: current_user
              )
      end

      context "when parent doesn't want to receive updates by text" do
        let(:parent) { parents.first }

        before { parent.update!(phone_receive_updates: false) }

        it "still enqueues a text" do
          expect { create_and_send! }.to have_delivered_sms(
            :clinic_subsequent_invitation
          ).with(
            parent:,
            patient:,
            programme_types:,
            team:,
            academic_year:,
            sent_by: current_user
          )
        end
      end
    end
  end
end
