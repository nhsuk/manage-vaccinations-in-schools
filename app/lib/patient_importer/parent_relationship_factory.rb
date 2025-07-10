# frozen_string_literal: true

module PatientImporter
  class ParentRelationshipFactory
    PARENT_ATTRIBUTES = %i[
      parent_1_name
      parent_1_email
      parent_1_phone
      parent_1_relationship
      parent_2_name
      parent_2_email
      parent_2_phone
      parent_2_relationship
    ].freeze

    PARENT_ATTRIBUTES.each do |attr|
      define_method(attr) { parent_attributes[attr] }
    end

    FamilyConnections =
      Struct.new(:parents, :parent_relationships) do
        def save!
          ActiveRecord::Base.transaction do
            parents&.each(&:save!)
            parent_relationships&.each(&:save!)
          end
        end
      end

    attr_reader :parent_attributes

    def initialize(row_data, patient, bulk_import: false)
      @patient = patient
      @bulk_import = bulk_import
      @parent_attributes = row_data.symbolize_keys.slice(*PARENT_ATTRIBUTES)
      @relationships = build_parent_relationships(patient)
    end

    def establish_family_connections
      return FamilyConnections.new([], []) if relationships.empty?

      parents = create_or_update_parents
      relationships = create_or_update_relationships(parents)

      FamilyConnections.new(parents, relationships)
    end

    private

    attr_reader :patient, :bulk_import, :relationships

    def create_or_update_parents
      relationships.map do |attributes|
        parent = find_or_initialize_parent(attributes)
        update_parent_attributes(parent, attributes)
        parent
      end
    end

    def create_or_update_relationships(parents)
      parents
        .zip(relationships)
        .map do |parent, attributes|
          create_or_update_relationship(parent, attributes)
        end
    end

    def create_or_update_relationship(parent, attributes)
      relationship_attributes = extract_relationship_attributes(attributes)

      ParentRelationship
        .find_or_initialize_by(parent:, patient:)
        .tap do |relationship|
          relationship.assign_attributes(relationship_attributes)
        end
    end

    def find_or_initialize_parent(attributes)
      Parent.match_existing(
        patient:,
        email: attributes[:email],
        phone: attributes[:phone],
        full_name: attributes[:full_name]
      ) || Parent.new
    end

    def update_parent_attributes(parent, attributes)
      parent.email = attributes[:email] if attributes[:email].present?
      parent.full_name = attributes[:full_name] if attributes[
        :full_name
      ].present?
      parent.phone = attributes[:phone] if attributes[:phone].present?
      parent.phone_receive_updates = false if parent.phone.blank?
    end

    def extract_relationship_attributes(attributes)
      { type: attributes[:type], other_name: attributes[:other_name] }.compact
    end

    def build_parent_relationships(patient)
      return [] if patient.pending_changes.any? && bulk_import

      parent_relationship_changes = []

      if parent_1_exists?
        parent_relationship_changes << {
          email: parent_1_email,
          full_name: parent_1_name,
          phone: parent_1_phone
        }.merge(parent_relationship_attributes(parent_1_relationship))
      end

      if parent_2_exists?
        parent_relationship_changes << {
          email: parent_2_email,
          full_name: parent_2_name,
          phone: parent_2_phone
        }.merge(parent_relationship_attributes(parent_2_relationship))
      end

      parent_relationship_changes
    end

    def parent_1_exists?
      [parent_1_name, parent_1_email, parent_1_phone].any?(&:present?)
    end

    def parent_2_exists?
      [parent_2_name, parent_2_email, parent_2_phone].any?(&:present?)
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
  end
end
