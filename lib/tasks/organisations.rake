# frozen_string_literal: true

namespace :organisations do
  desc "Add a programme to an organisation."
  task :add_programme, %i[ods_code type] => :environment do |_task, args|
    organisation = Organisation.find_by!(ods_code: args[:ods_code])
    programme = Programme.find_by!(type: args[:type])

    OrganisationProgramme.find_or_create_by!(organisation:, programme:)

    GenericClinicFactory.call(organisation: organisation.reload)
  end
end
