# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_changesets
#
#  id              :bigint           not null, primary key
#  import_type     :string           not null
#  pending_changes :jsonb            not null
#  row_number      :integer          not null
#  status          :integer          default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  import_id       :bigint           not null
#  patient_id      :bigint
#  school_id       :bigint
#
# Indexes
#
#  index_patient_changesets_on_import      (import_type,import_id)
#  index_patient_changesets_on_patient_id  (patient_id)
#  index_patient_changesets_on_status      (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (school_id => locations.id)
#
class PatientChangeset < ApplicationRecord
  attribute :pending_changes,
            :jsonb,
            default: {
              child: {
              },
              parent_1: {
              },
              parent_2: {
              },
              pds: {
              }
            }

  belongs_to :import, polymorphic: true
  belongs_to :school, class_name: "Location", optional: true

  enum :status, { pending: 0, processed: 1 }, validate: true

  def self.from_import_row(row:, import:, row_number:)
    create!(
      import:,
      row_number:,
      school: row.school,
      pending_changes: {
        child: row.import_attributes,
        academic_year: row.academic_year,
        home_educated: row.home_educated,
        # TODO: This should gotten from the import, but it does not provide.
        #       Maybe one day.
        school_move_source: row.school_move_source,
        parent_1: row.parent_1_import_attributes,
        parent_2: row.parent_2_import_attributes
      }
    )
  end

  delegate :team, to: :import

  def child_attributes = pending_changes["child"]

  def parent_1_attributes = pending_changes["parent_1"]

  def parent_2_attributes = pending_changes["parent_2"]

  def academic_year = pending_changes["academic_year"]

  def home_educated = pending_changes["home_educated"]

  def school_move_source = pending_changes["school_move_source"]

  def patient
    @patient ||=
      if (existing_patient = existing_patients.first)
        prepare_patient_changes(existing_patient, pending_changes)
      else
        Patient.new(
          child_attributes.merge(
            "home_educated" => false,
            "patient_sessions" => []
          )
        )
      end
  end

  def parents
    @parents ||=
      [parent_1_attributes.presence, parent_2_attributes.presence].compact
        .map do |attrs|
        parent =
          Parent.match_existing(
            patient: existing_patients.first,
            email: attrs[:email],
            phone: attrs[:phone],
            full_name: attrs[:full_name]
          ) || Parent.new

        parent.email = attrs[:email] if attrs[:email]
        parent.full_name = attrs[:full_name] if attrs[:full_name]
        parent.phone = attrs[:phone] if attrs[:phone]
        parent.phone_receive_updates = false if parent.phone.blank?

        parent
      end
  end

  def parent_relationships
    @parent_relationships ||=
      [
        parent_1_attributes["relationship"],
        parent_2_attributes["relationship"]
      ].compact
        .map { parent_relationship_attributes(it) }
        .zip(parents)
        .map do |relationship, parent|
          ParentRelationship
            .find_or_initialize_by(parent:, patient:)
            .tap { it.assign_attributes(relationship) }
        end
  end

  def parent_relationship_attributes(relationship)
    case relationship&.downcase
    when nil, "unknown"
      { type: "unknown" }
    when "mother", "mum"
      { type: "mother" }
    when "father", "dad"
      { type: "father" }
    when "guardian"
      { type: "guardian" }
    else
      { type: "other", other_name: relationship }
    end
  end

  def school_move
    @school_move ||=
      begin
        return if patient.deceased?
        if patient.new_record? || patient.school != school ||
             patient.home_educated != home_educated ||
             patient.not_in_team?(team:, academic_year:) ||
             patient.archived?(team:)
          school_move =
            if school
              SchoolMove.find_or_initialize_by(patient:, school:)
            else
              SchoolMove.find_or_initialize_by(patient:, home_educated:, team:)
            end

          school_move.tap do
            it.academic_year = academic_year
            it.source = school_move_source
          end
        end
      end
  end

  def existing_patients
    @existing_patients ||=
      begin
        deserialize_attribute(child_attributes, "date_of_birth", :date)

        if child_attributes["given_name"].blank? ||
             child_attributes["family_name"].blank? ||
             child_attributes["date_of_birth"]&.nil?
          return []
        end

        Patient.includes(:patient_sessions).match_existing(
          nhs_number: child_attributes["nhs_number"],
          given_name: child_attributes["given_name"],
          family_name: child_attributes["family_name"],
          date_of_birth: child_attributes["date_of_birth"],
          address_postcode: child_attributes["address_postcode"]
        )
      end
  end

  def prepare_patient_changes(existing_patient, pending_changes)
    unless stage_registration?
      existing_patient.registration = pending_changes.delete(:registration)
      existing_patient.registration_academic_year =
        pending_changes.delete(:registration_academic_year)
    end

    auto_accept_child_attributes(existing_patient)
    handle_address_updates(existing_patient)
    stage_and_handle_pending_changes(existing_patient)

    existing_patient
  end

  def auto_accept_child_attributes(existing_patient)
    set_child_attribute_if_valid(:preferred_given_name, existing_patient)
    set_child_attribute_if_valid(:preferred_family_name, existing_patient)
    set_child_attribute_if_valid(
      :gender_code,
      existing_patient,
      %w[male female not_specified]
    )
  end

  def set_child_attribute_if_valid(
    attribute,
    existing_patient,
    valid_values = nil
  )
    if valid_values.nil?
      in_pending_changes = child_attributes[attribute.to_s].present?
      in_existing_patient = existing_patient[attribute.to_s].present?
    else
      in_pending_changes = child_attributes[attribute.to_s].in? valid_values
      in_existing_patient = existing_patient[attribute.to_s].in? valid_values
    end

    if in_pending_changes && !in_existing_patient
      existing_patient[attribute] = child_attributes[attribute.to_s]
    end
  end

  def stage_registration?
    import_type == "CohortImport"
  end

  def deserialize_attribute(attributes, key, type)
    if attributes.key?(key) && attributes[key].is_a?(String)
      attributes[key] = case type
      when :date
        attributes[key].to_date
      when :datetime
        Time.iso8601(attributes[key])
      end
    end
  end

  def handle_address_updates(existing_patient)
    if child_attributes["address_postcode"].present? &&
         child_attributes["address_postcode"] !=
           existing_patient.address_postcode
      # If the postcode is different then we need to reset any address fields
      # that were nil to ensure they when we merge we don't leave any old
      # values.
      #
      # NOTE: This may also be achievable by removing the `&` from
      #       `address_line_1&.to_s` in PatientImportRow#import_attributes, but
      #       this needs to be tested.
      child_attributes["address_line_1"] ||= nil
      child_attributes["address_line_2"] ||= nil
      child_attributes["address_town"] ||= nil
    elsif auto_overwrite_address?(existing_patient)
      existing_patient.address_line_1 =
        child_attributes.delete("address_line_1")
      existing_patient.address_line_2 =
        child_attributes.delete("address_line_2")
      existing_patient.address_town = child_attributes.delete("address_town")
    end
  end

  def auto_overwrite_address?(existing_patient)
    existing_patient.address_postcode == child_attributes["address_postcode"] &&
      [
        child_attributes["address_line_1"],
        child_attributes["address_line_2"],
        child_attributes["address_town"]
      ].any?(&:present?)
  end

  def stage_and_handle_pending_changes(existing_patient)
    auto_accepted_changes = existing_patient.changed_attributes.keys

    existing_patient.stage_changes(child_attributes)

    # If there are pending changes that require review, we need to revert
    # any auto-accepted changes and move them to pending_changes instead.
    # This ensures all changes are reviewed together rather than having
    # some changes applied immediately while others await review. This
    # is particularly critical when handling potential duplicates like twins,
    # where auto-accepting some changes could lead to data from one twin being
    # incorrectly applied to another twin's record.
    if existing_patient.pending_changes.any?
      existing_patient.pending_changes.merge!(
        existing_patient.slice(*auto_accepted_changes)
      )
      existing_patient.restore_attributes(auto_accepted_changes)
    end
  end
end
