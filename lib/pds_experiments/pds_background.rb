# frozen_string_literal: true

module PDSExperiments
  class PDSBackground
    def patient_data_report(organisation_id)
      organisation = Organisation.find(organisation_id)
      patients = Patient.where(organisation:)
      patient_ids = patients.pluck(:id)

      # Audits for NHS number added later - process in chunks
      nhs_added_ids = []
      nhs_from_pds_ids = []
      nhs_manually_added_ids = []

      patient_ids.each_slice(500) do |patient_chunk|
        Audited::Audit
          .where(auditable_type: "Patient", auditable_id: patient_chunk)
          .where.not(action: "create")
          .find_each do |audit|
            changes = audit.audited_changes
            nhs_change = changes["nhs_number"]

            # Check if NHS number was added (nil -> value)
            unless nhs_change.is_a?(Array) && nhs_change[0].nil? &&
                     !nhs_change[1].nil?
              next
            end
            nhs_added_ids << audit.auditable_id

            # Check if it was from PDS (has both nhs_number and updated_from_pds_at changes)
            if changes.key?("updated_from_pds_at")
              nhs_from_pds_ids << audit.auditable_id
            else
              nhs_manually_added_ids << audit.auditable_id
            end
          end
      end

      nhs_added_ids.uniq!
      nhs_from_pds_ids.uniq!
      nhs_manually_added_ids.uniq!

      total_patients = patients.count

      # NHS Number stats
      with_nhs_count = patients.where.not(nhs_number: nil).count
      uploaded_with_nhs_count =
        patients.where.not(nhs_number: nil).where.not(id: nhs_added_ids).count
      nhs_added_later_count = nhs_added_ids.size
      nhs_from_pds_count = nhs_from_pds_ids.size
      nhs_manually_added_count = nhs_manually_added_ids.size

      # Gender stats
      without_gender_count = patients.not_known.count
      with_gender_count = total_patients - without_gender_count

      # Consent stats
      total_consents = Consent.where(organisation_id:).count
      auto_matched_consents =
        Consent.where(organisation_id:, recorded_by_user_id: nil).count
      manually_recorded_consents = total_consents - auto_matched_consents

      puts <<~REPORT
      Patient Data Report
      ==========================

      Organisation: #{organisation.name} (ID: #{organisation.id})

      NHS Number Statistics:
      ---------------------------
      Total Patients:           #{total_patients.to_s.rjust(6)} (100.0%)
      With NHS Number:          #{with_nhs_count.to_s.rjust(6)} (#{((with_nhs_count.to_f / total_patients) * 100).round(1).to_s.rjust(5)}%)
        - Uploaded with NHS:    #{uploaded_with_nhs_count.to_s.rjust(6)} (#{((uploaded_with_nhs_count.to_f / total_patients) * 100).round(1).to_s.rjust(5)}%)
        - Added NHS Later:      #{nhs_added_later_count.to_s.rjust(6)} (#{((nhs_added_later_count.to_f / total_patients) * 100).round(1).to_s.rjust(5)}%)
          • From PDS:           #{nhs_from_pds_count.to_s.rjust(6)} (#{((nhs_from_pds_count.to_f / total_patients) * 100).round(1).to_s.rjust(5)}%)
          • Manually Added:     #{nhs_manually_added_count.to_s.rjust(6)} (#{((nhs_manually_added_count.to_f / total_patients) * 100).round(1).to_s.rjust(5)}%)
      Without NHS Number:       #{(total_patients - with_nhs_count).to_s.rjust(6)} (#{(((total_patients - with_nhs_count).to_f / total_patients) * 100).round(1).to_s.rjust(5)}%)

      Gender Statistics:
      ---------------------------
      With Gender Code:         #{with_gender_count.to_s.rjust(6)} (#{((with_gender_count.to_f / total_patients) * 100).round(1).to_s.rjust(5)}%)
      Without Gender Code:      #{without_gender_count.to_s.rjust(6)} (#{((without_gender_count.to_f / total_patients) * 100).round(1).to_s.rjust(5)}%)

      Consent Statistics:
      ---------------------------
      Total Consents:           #{total_consents.to_s.rjust(6)} (100.0%)
      Auto-matched Consents:    #{auto_matched_consents.to_s.rjust(6)} (#{total_consents.positive? ? ((auto_matched_consents.to_f / total_consents) * 100).round(1).to_s.rjust(5) : "0.0".rjust(5)}%)
      Manually Recorded:        #{manually_recorded_consents.to_s.rjust(6)} (#{total_consents.positive? ? ((manually_recorded_consents.to_f / total_consents) * 100).round(1).to_s.rjust(5) : "0.0".rjust(5)}%)
    REPORT
    end
  end
end
