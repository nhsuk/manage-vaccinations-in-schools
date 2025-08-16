# frozen_string_literal: true

require_relative "../../mavis_cli"

module MavisCLI
  module Generate
    class ConsentForms < Dry::CLI::Command
      desc "Generate consent forms"

      argument :session_slug,
               desc: "Slug of the session to generate consent forms for"

      def call(session_slug:, **)
        MavisCLI.load_rails

        session = Session.find_by!(slug: session_slug)

        patients = session.patients.includes(:school)

        puts "Found #{patients.count} patients"
        puts "Generating consent forms..."

        # 10% refused
        patients
          .sample(patients.count * 0.1)
          .each do |patient|
            consent_form =
              FactoryBot.create(
                :consent_form,
                :refused,
                :recorded,
                session:,
                given_name: patient.given_name,
                family_name: patient.family_name,
                date_of_birth: patient.date_of_birth,
                address_postcode: patient.address_postcode
              )
            consent_form.match_with_patient!(patient, current_user: nil)
          end

        # 50% given
        patients
          .sample(patients.count * 0.5)
          .each do |patient|
            consent_form =
              FactoryBot.create(
                :consent_form,
                :recorded,
                session:,
                given_name: patient.given_name,
                family_name: patient.family_name,
                date_of_birth: patient.date_of_birth,
                address_postcode: patient.address_postcode
              )
            consent_form.match_with_patient!(patient, current_user: nil)
          end

        # 20% given with health questions
        patients
          .sample(patients.count * 0.2)
          .each do |patient|
            consent_form =
              FactoryBot.create(
                :consent_form,
                :with_health_answers_no_branching,
                :recorded,
                session:,
                given_name: patient.given_name,
                family_name: patient.family_name,
                date_of_birth: patient.date_of_birth,
                address_postcode: patient.address_postcode
              )
            consent_form.match_with_patient!(patient, current_user: nil)
          end

        # 10% given with health answers branching
        patients
          .sample(patients.count * 0.10)
          .each do |patient|
            consent_form =
              FactoryBot.create(
                :consent_form,
                :with_health_answers_no_branching,
                :recorded,
                session:,
                given_name: patient.given_name,
                family_name: patient.family_name,
                date_of_birth: patient.date_of_birth,
                address_postcode: patient.address_postcode
              )
            consent_form.match_with_patient!(patient, current_user: nil)
          end

        puts "Successfully generated consent forms"
      end
    end
  end

  register "generate", aliases: ["g"] do |prefix|
    prefix.register "consent-forms", Generate::ConsentForms
  end
end
