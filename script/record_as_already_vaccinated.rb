# frozen_string_literal: true

# urn = "123456"
# patient_ids_need_vaccination = "<paste>".split("\n")

# year_groups = [10, 11]
# programmes = [Programme.find_by(type: "menacwy"), Programme.find_by(type: "td_ipv")]

year_groups = [9, 10, 11]
programmes = [Programme.find_by(type: "hpv")]

school = Location.find_by(urn:)

session = school.sessions.first

puts "School has #{session.patients.count} patients"

patient_sessions =
  session
    .patient_sessions
    .preload_for_status
    .where.not(patient_id: patient_ids_need_vaccination)
    .select { it.patient.year_group.in?(year_groups) }

puts "Of which #{patient_sessions.length} might need to be marked as vaccinated"

patient_sessions.each do |patient_session|
  programmes.each do |programme|
    if patient_session.vaccination_administered?(programme:) ||
         patient_session.unable_to_vaccinate?(programme:) ||
         patient_session.patient.consents.exists?(programme:)
      next
    end

    VaccinationRecord.create!(
      patient: patient_session.patient,
      location_name: session.location.name,
      programme:,
      outcome: :already_had,
      performed_at: Time.current
    )
  end
end
