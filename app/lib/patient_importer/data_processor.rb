# frozen_string_literal: true

module PatientImporter
  class DataProcessor
    PATIENT_ATTRIBUTES = %i[
      address_line_1
      address_line_2
      address_postcode
      address_town
      birth_academic_year
      date_of_birth
      family_name
      gender_code
      given_name
      nhs_number
      preferred_family_name
      preferred_given_name
      registration
    ].freeze

    ProcessedPatientData =
      Struct.new(:patient, :parents, :parent_relationships, :school_move)

    PATIENT_ATTRIBUTES.each do |attr|
      define_method(attr) { patient_attributes[attr] }
    end

    def initialize(
      row_data,
      stage_registration: false,
      bulk_import: false,
      school: nil,
      organisation: nil
    )
      @row_data = row_data.symbolize_keys
      @stage_registration = stage_registration
      @bulk_import = bulk_import
      @school = school
      @organisation = organisation
      @patient_attributes = @row_data.slice(*PATIENT_ATTRIBUTES)
    end

    def call
      patient =
        if (existing_patient = existing_patients&.first)
          prepare_patient_changes(existing_patient)
        else
          Patient.new(
            patient_attributes.merge(home_educated: false, patient_sessions: [])
          )
        end

      family_relationship_factory =
        ParentRelationshipFactory.new(row_data, patient, bulk_import:)

      school_move_factory =
        SchoolMoveFactory.new(
          row_data,
          patient,
          school:,
          organisation:,
          bulk_import:
        )

      if patient.pending_changes.any?
        patient.pending_changes.merge!(
          family_relationship_factory.parent_attributes
        )
        patient.pending_changes.merge!(
          school_move_factory.school_related_attributes
        )
      end

      family_connections =
        family_relationship_factory.establish_family_connections

      ProcessedPatientData.new(
        patient,
        family_connections.parents,
        family_connections.parent_relationships,
        school_move_factory.resolve_school_move
      )
    end

    def self.call(...) = new(...).call

    private_class_method :new

    private

    attr_reader :row_data,
                :patient_attributes,
                :stage_registration,
                :bulk_import,
                :school,
                :organisation

    def existing_patients
      return if given_name.blank? || family_name.blank? || date_of_birth.blank?

      Patient.includes(:patient_sessions).match_existing(
        nhs_number: nhs_number,
        given_name: given_name,
        family_name: family_name,
        date_of_birth: date_of_birth,
        address_postcode: address_postcode
      )
    end

    def prepare_patient_changes(patient)
      patient.registration =
        patient_attributes.delete(:registration) unless stage_registration

      auto_accept_attributes_if_applicable(patient)
      handle_address_updates(patient)
      stage_and_handle_pending_changes(patient)

      patient
    end

    def auto_accept_attributes_if_applicable(patient)
      auto_accept_attribute(
        patient,
        :gender_code,
        :in?,
        %w[male female not_specified]
      )

      auto_accept_attribute(patient, :preferred_given_name, :present?)
      auto_accept_attribute(patient, :preferred_family_name, :present?)
    end

    def auto_accept_attribute(patient, attr_name, predicate, *predicate_args)
      present_in_import =
        patient_attributes[attr_name].public_send(predicate, *predicate_args)
      present_in_patient =
        patient[attr_name].public_send(predicate, *predicate_args)
      if present_in_import && !present_in_patient
        patient[attr_name] = patient_attributes[attr_name]
      end
    end

    def handle_address_updates(patient)
      if address_postcode.present? &&
           address_postcode != patient.address_postcode
        patient_attributes.merge!(
          address_line_1: address_line_1&.to_s,
          address_line_2: address_line_2&.to_s,
          address_town: address_town&.to_s
        )
      elsif auto_overwrite_address?(patient)
        patient.address_line_1 = patient_attributes.delete(:address_line_1)
        patient.address_line_2 = patient_attributes.delete(:address_line_2)
        patient.address_town = patient_attributes.delete(:address_town)
      end
    end

    def auto_overwrite_address?(existing_patient)
      existing_patient.address_postcode == address_postcode &&
        [address_line_1, address_line_2, address_town].any?(&:present?)
    end

    def stage_and_handle_pending_changes(patient)
      auto_accepted_changes = patient.changed_attributes.keys

      patient.stage_changes(patient_attributes)

      # If there are pending changes that require review, we need to revert
      # any auto-accepted changes and move them to pending_changes instead.
      # This ensures all changes are reviewed together rather than having
      # some changes applied immediately while others await review. This
      # is particularly critical when handling potential duplicates like twins,
      # where auto-accepting some changes could lead to data from one twin being
      # incorrectly applied to another twin's record.
      if patient.pending_changes.any?
        patient.pending_changes.merge!(patient.slice(*auto_accepted_changes))
        patient.restore_attributes(auto_accepted_changes)
      end
    end
  end
end
