# frozen_string_literal: true

# == Schema Information
#
# Table name: reporting_api_vaccination_events
#
#  id                                               :bigint           not null, primary key
#  event_timestamp                                  :datetime         not null
#  event_timestamp_academic_year                    :integer          not null
#  event_timestamp_day                              :integer          not null
#  event_timestamp_month                            :integer          not null
#  event_timestamp_year                             :integer          not null
#  event_type                                       :string           not null
#  location_address_postcode                        :string
#  location_address_town                            :string
#  location_local_authority_mhclg_code              :string
#  location_local_authority_short_name              :string
#  location_name                                    :string
#  location_type                                    :string
#  organisation_name                                :string
#  organisation_ods_code                            :string
#  patient_address_postcode                         :string
#  patient_address_town                             :string
#  patient_birth_academic_year                      :integer
#  patient_date_of_death                            :date
#  patient_gender_code                              :string
#  patient_home_educated                            :boolean
#  patient_local_authority_from_postcode_mhclg_code :string
#  patient_local_authority_from_postcode_short_name :string
#  patient_school_address_postcode                  :string
#  patient_school_address_town                      :string
#  patient_school_gias_local_authority_code         :integer
#  patient_school_local_authority_mhclg_code        :string
#  patient_school_local_authority_short_name        :string
#  patient_school_name                              :string
#  patient_school_type                              :string
#  patient_year_group                               :integer
#  programme_type                                   :string
#  source_type                                      :string           not null
#  team_name                                        :string
#  vaccination_record_outcome                       :string
#  vaccination_record_performed_at                  :datetime
#  vaccination_record_uuid                          :uuid
#  created_at                                       :datetime         not null
#  updated_at                                       :datetime         not null
#  location_id                                      :bigint
#  organisation_id                                  :bigint
#  patient_id                                       :bigint           not null
#  patient_school_id                                :bigint
#  programme_id                                     :bigint
#  source_id                                        :bigint           not null
#  team_id                                          :bigint
#  vaccination_record_programme_id                  :bigint
#  vaccination_record_session_id                    :bigint
#
# Indexes
#
#  index_reporting_api_vaccination_events_on_source  (source_type,source_id)
#  ix_rve_ac_year_month                              (event_timestamp_academic_year,event_timestamp_month)
#  ix_rve_acyear_month_type                          (event_timestamp_academic_year,event_timestamp_month,event_type)
#  ix_rve_prog_acyear_month                          (programme_id,event_timestamp_academic_year,event_timestamp_month)
#  ix_rve_source_type_id                             (source_type,source_id)
#  ix_rve_team_acyr_month                            (team_id,event_timestamp_academic_year,event_timestamp_month)
#  ix_rve_tstamp                                     (event_timestamp)
#
describe ReportingAPI::VaccinationEvent do
  let!(:flu) { Programme.flu.first || create(:programme, type: "flu") }

  let(:location) { create(:school, name: "St Vaxes") }
  let(:sample_session) do
    create(:session, location: location, programmes: [flu])
  end

  describe ".with_count_of_patients_vaccinated" do
    let(:patient_a) { create(:patient, random_nhs_number: true, year_group: 7) }
    let(:patient_b) { create(:patient, random_nhs_number: true, year_group: 7) }
    let(:patient_c) { create(:patient, random_nhs_number: true, year_group: 8) }

    before do
      create_list(
        :reporting_api_vaccination_event,
        2,
        for_patient: patient_a,
        year_group: 7,
        outcome: "administered",
        session: sample_session
      )
      create_list(
        :reporting_api_vaccination_event,
        1,
        for_patient: patient_b,
        year_group: 7,
        outcome: "already_had",
        session: sample_session
      )
      create_list(
        :reporting_api_vaccination_event,
        3,
        for_patient: patient_c,
        year_group: 8,
        outcome: "administered",
        session: sample_session
      )
    end

    context "on a grouped resultset" do
      subject(:resultset) { described_class.group(:patient_year_group) }

      let(:results) do
        resultset
          .select(:patient_year_group)
          .with_count_of_patients_vaccinated
          .to_a
      end

      it "adds total_patients_vaccinated to the resultset" do
        expect(results).to all(have_attribute(:total_patients_vaccinated))
      end

      describe "the total_patients_vaccinated attribute" do
        it "equals the count of records in the current group with vaccination_record_outcome: 'administered'" do
          expect(
            results
              .find { |event| event.patient_year_group == 7 }
              .total_patients_vaccinated
          ).to eq(1)
          expect(
            results
              .find { |event| event.patient_year_group == 8 }
              .total_patients_vaccinated
          ).to eq(1)
        end
      end
    end
  end

  describe ".with_counts_of_outcomes" do
    before do
      create_list(
        :reporting_api_vaccination_event,
        2,
        year_group: 7,
        session: sample_session,
        outcome: "administered"
      )
      create_list(
        :reporting_api_vaccination_event,
        1,
        year_group: 7,
        session: sample_session,
        outcome: "already_had"
      )
      create_list(
        :reporting_api_vaccination_event,
        3,
        year_group: 8,
        session: sample_session,
        outcome: "administered"
      )
      create_list(
        :reporting_api_vaccination_event,
        2,
        year_group: 8,
        session: sample_session,
        outcome: "already_had"
      )
    end

    context "on a grouped resultset" do
      subject(:resultset) { described_class.group(:patient_year_group) }

      let(:results) do
        resultset.select(:patient_year_group).with_counts_of_outcomes.to_a
      end

      it "adds total_vaccinations_performed to the resultset" do
        expect(resultset.with_counts_of_outcomes).to all(
          have_attribute(:total_vaccinations_performed)
        )
      end

      describe "the total_vaccinations_performed attribute" do
        it "equals the count of records in the current group with vaccination_record_outcome: 'administered'" do
          expect(
            results
              .find { |event| event.patient_year_group == 7 }
              .total_vaccinations_performed
          ).to eq(2)
          expect(
            results
              .find { |event| event.patient_year_group == 8 }
              .total_vaccinations_performed
          ).to eq(3)
        end
      end
    end
  end
end
