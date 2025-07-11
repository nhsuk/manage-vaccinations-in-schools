# frozen_string_literal: true

module PatientImporter
  class SchoolMoveFactory
    SCHOOL_MOVE_RELATED_ATTRIBUTES = %i[
      school_move_home_educated
      school_move_source
      school_move_school_id
      school_move_organisation_id
    ].freeze

    SCHOOL_MOVE_RELATED_ATTRIBUTES.each do |attr|
      define_method(attr) { school_related_attributes[attr] }
    end

    attr_reader :school_related_attributes

    def initialize(
      row_data,
      patient,
      school: nil,
      organisation: nil,
      bulk_import: false
    )
      @patient = patient
      @bulk_import = bulk_import
      @school_related_attributes =
        row_data.symbolize_keys.slice(*SCHOOL_MOVE_RELATED_ATTRIBUTES)
      @school = school || Location.find_by(id: school_move_school_id)
      @organisation =
        organisation || Organisation.find_by(id: school_move_organisation_id)
    end

    def resolve_school_move
      return nil if patient.pending_changes.any? && bulk_import

      if patient.new_record? || patient.school != school ||
           patient.home_educated != school_move_home_educated ||
           patient.not_in_organisation?
        school_move =
          if school
            SchoolMove.find_or_initialize_by(patient:, school:)
          else
            SchoolMove.find_or_initialize_by(
              patient:,
              organisation:,
              home_educated: school_move_home_educated
            )
          end

        school_move.tap { _1.source = school_move_source }
      end
    end

    private

    attr_reader :patient, :school, :organisation, :bulk_import
  end
end
