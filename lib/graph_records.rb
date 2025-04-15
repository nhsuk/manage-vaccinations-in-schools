# frozen_string_literal: true

require "digest"

# Spit out a Mermaid-style graph of records.
#
# Usage:
#  graph = GraphRecords.new.graph(patients: [patient])
#  puts graph
#
class GraphRecords
  # TODO: put all these constants elsewhere?
  BOX_STYLES = %w[
    fill:#e6194B,color:white
    fill:#3cb44b,color:white
    fill:#ffe119,color:black
    fill:#4363d8,color:white
    fill:#f58231,color:white
    fill:#911eb4,color:white
    fill:#42d4f4,color:black
    fill:#f032e6,color:white
    fill:#bfef45,color:black
    fill:#fabed4,color:black
    fill:#469990,color:white
    fill:#dcbeff,color:black
    fill:#9A6324,color:white
    fill:#fffac8,color:black
    fill:#800000,color:white
    fill:#aaffc3,color:black
    fill:#808000,color:white
    fill:#ffd8b1,color:black
    fill:#000075,color:white
    fill:#a9a9a9,color:white
    fill:#ffffff,color:black
    fill:#000000,color:white
  ].freeze

  DEFAULT_NODE_ORDER = %w[
    programme
    organisation
    team
    location
    session
    session_date
    class_import
    cohort_import
    patient_session
    session_attendance
    gillick_assessment
    patient
    vaccine
    batch
    vaccination_record
    triage
    user
    consent
    consent_form
    parent_relationship
    parent
  ].freeze

  ALLOWED_TYPES = DEFAULT_NODE_ORDER

  DEFAULT_TRAVERSALS = {
    patient: {
      patient: %i[
        parents
        consents
        cohort_imports
        class_imports
        vaccination_records
        patient_sessions
        triages
        school
      ],
      parent: %i[patients consents cohort_imports class_imports],
      consent: %i[consent_form patient parent],
      session: %i[location],
      patient_session: %i[session session_attendances gillick_assessments],
      vaccination_record: %i[session]
    },
    parent: {
      parent: %i[class_imports cohort_imports consents patients],
      class_import: %i[session],
      consent: %i[parent patient],
      patient: %i[parents sessions consents],
      session: %i[location]
    },
    consent: {
      consent: %i[consent_form parent patient programme],
      parent: %i[patients],
      patient: %i[parents]
    },
    consent_form: {
      consent_form: [:consent]
    },
    vaccination_record: {
      vaccination_record: %i[
        patient
        programme
        session
        vaccine
        performed_by_user
      ],
      patient: [:consents],
      session: [:location],
      consent: [:programme]
    },
    location: {
      location: %i[sessions team]
    },
    session: {
      session: %i[location programmes session_dates]
    },
    session_attendance: {
      session_attendance: %i[patient_session session_date],
      patient_session: %i[session gillick_assessments patient],
      session: %i[location],
      session_date: %i[session]
    },
    patient_session: {
      patient_session: %i[
        session
        patient
        session_attendances
        gillick_assessments
      ],
      session: %i[location]
    },
    gillick_assessment: {
      gillick_assessment: %i[patient_session performed_by programme],
      patient_session: %i[session patient],
      session: %i[location]
    },
    triage: {
      triage: %i[patient performed_by programme]
    },
    programme: {
      programme: %i[teams vaccines]
    },
    organisation: {
      organisation: %i[teams]
    },
    team: {
      team: %i[organisation programmes]
    },
    vaccine: {
      vaccine: %i[batches programme]
    },
    batch: {
      batch: %i[team vaccine],
      vaccine: [:programme]
    },
    user: {
      user: %i[teams programmes],
      team: [:programmes]
    },
    session_date: {
      session_date: [:session],
      session: %i[location]
    },
    cohort_import: {
      cohort_import: %i[team uploaded_by]
    },
    class_import: {
      class_import: %i[team uploaded_by]
    }
  }.freeze

  DETAIL_WHITELIST = {
    consent: %i[
      response
      route
      created_at
      updated_at
      withdrawn_at
      invalidated_at
    ],
    session: %i[slug clinic? academic_year],
    session_attendance: %i[attending created_at updated_at],
    triage: %i[status created_at updated_at invalidated_at],
    vaccination_record: %i[
      outcome
      performed_at
      created_at
      updated_at
      discarded_at
      uuid
    ],
    programme: %i[type],
    vaccine: %i[nivs_name],
    organisation: %i[ods_code],
    team: %i[name workgroup],
    location: %i[name type year_groups],
    cohort_import: %i[
      csv_filename
      processed_at
      status
      rows_count
      new_record_count
      exact_duplicate_record_count
      changed_record_count
    ],
    class_import: %i[
      csv_filename
      processed_at
      status
      rows_count
      new_record_count
      exact_duplicate_record_count
      changed_record_count
      year_groups
    ],
    session_date: %i[value],
    patient: %i[
      updated_from_pds_at
      date_of_death_recorded_at
      restricted_at
      invalidated_at
    ],
    parent: %i[],
    patient_session: %i[],
    gillick_assessment: %i[created_at],
    batch: %i[name expiry archived_at],
    user: %i[fallback_role uid],
    consent_form: %i[response recorded_at archived_at],
    parent_relationship: %i[type]
  }.freeze

  DETAIL_WHITELIST_WITH_PII = {
    consent: %i[
      response
      route
      created_at
      updated_at
      withdrawn_at
      invalidated_at
    ],
    session: %i[slug clinic? academic_year],
    session_attendance: %i[attending created_at updated_at],
    triage: %i[status created_at updated_at invalidated_at],
    vaccination_record: %i[
      outcome
      performed_at
      created_at
      updated_at
      discarded_at
      uuid
    ],
    programme: %i[type],
    vaccine: %i[nivs_name],
    organisation: %i[name ods_code],
    location: %i[name address_postcode type year_groups],
    cohort_import: %i[
      csv_filename
      processed_at
      status
      rows_count
      new_record_count
      exact_duplicate_record_count
      changed_record_count
    ],
    class_import: %i[
      csv_filename
      processed_at
      status
      rows_count
      new_record_count
      exact_duplicate_record_count
      changed_record_count
      year_groups
    ],
    session_date: %i[value],
    team: %i[name],
    patient: %i[
      nhs_number
      given_name
      family_name
      date_of_birth
      address_line_1
      address_line_2
      address_town
      address_postcode
      home_educated
      updated_from_pds_at
      restricted_at
      date_of_death
      date_of_death_recorded_at
      updated_from_pds_at
      invalidated_at
      pending_changes
    ],
    parent: %i[full_name email phone],
    patient_session: %i[],
    gillick_assessment: %i[
      knows_vaccination
      knows_disease
      knows_consequences
      knows_delivery
      knows_side_effects
      created_at
    ],
    batch: %i[name expiry archived_at],
    user: %i[given_name family_name email fallback_role uid],
    consent_form: %i[
      response
      recorded_at
      archived_at
      given_name
      family_name
      address_postcode
      date_of_birth
    ],
    parent_relationship: %i[type other_name]
  }.freeze

  # @param focus_config [Hash] Hash of model names to ids to focus on (make bold)
  # @param node_order [Array] Array of model names in order to render nodes
  # @param traversals_config [Hash] Hash of model names to arrays of associations to traverse
  # @param node_limit [Integer] The maximum number of nodes which can be displayed
  def initialize(
    focus_config: {},
    node_order: DEFAULT_NODE_ORDER,
    traversals_config: {},
    node_limit: 1000,
    primary_type: nil,
    clickable: false
  )
    @focus_config = focus_config
    @node_order = node_order
    @traversals_config = traversals_config
    @node_limit = node_limit
    @primary_type = primary_type
    @clickable = clickable
  end

  # @param objects [Hash] Hash of model name to ids to be graphed
  def graph(**objects)
    @nodes = Set.new
    @edges = Set.new
    @inspected = Set.new
    @focus = @focus_config.map { _1.to_s.classify.constantize.where(id: _2) }

    @primary_type ||=
      if objects.keys.size >= 1
        objects.keys.first.to_s.singularize.to_sym
      else
        :patient
      end

    objects.map do |klass, ids|
      class_name = klass.to_s.singularize
      associated_objects =
        load_association(class_name.classify.constantize.where(id: ids))

      @focus += associated_objects

      associated_objects.each do |obj|
        @nodes << obj
        introspect(obj)
      end
    end
    ["flowchart TB"] + render_styles + render_nodes + render_edges +
      (@clickable ? render_clicks : [])
  rescue StandardError => e
    if e.message.include?("Recursion limit")
      # Create a Mermaid diagram with a red box containing the error message.
      [
        "flowchart TB",
        "    error[#{e.message}]",
        "    style error fill:#f88,stroke:#f00,stroke-width:2px"
      ]
    else
      raise e
    end
  end

  def traversals
    @traversals ||=
      (DEFAULT_TRAVERSALS[@primary_type] || {}).merge(@traversals_config)
  end

  def render_styles
    object_types = @nodes.map { |node| node.class.name.underscore.to_sym }.uniq

    styles =
      object_types.each_with_object({}) do |type, hash|
        color_index =
          Digest::MD5.hexdigest(type.to_s).to_i(16) % BOX_STYLES.length
        hash[type] = "#{BOX_STYLES[color_index]},stroke:#000"
      end

    focused_styles =
      styles.each_with_object({}) do |(type, style), hash|
        hash["#{type}_focused"] = "#{style},stroke-width:3px"
      end

    styles.merge!(focused_styles)

    styles
      .with_indifferent_access
      .slice(*@nodes.map { class_text_for_obj(it) })
      .map { |klass, style| "  classDef #{klass} #{style}" }
  end

  def render_nodes
    @nodes.to_a.map { "  #{node_with_class(it)}" }
  end

  def render_edges
    @edges.map { |from, to| "  #{node_name(from)} --> #{node_name(to)}" }
  end

  def render_clicks
    @nodes.map { "  click #{node_name(it)} \"#{node_link(it)}\"" }
  end

  def introspect(obj)
    associations_list = traversals[obj.class.name.underscore.to_sym]
    return if associations_list.blank?

    return if @inspected.include?(obj)
    @inspected << obj

    associations_list.each do
      get_associated_objects(obj, it).each do
        @nodes << it
        @edges << order_nodes(obj, it)

        if @nodes.length > @node_limit
          raise "Recursion limit of #{@node_limit} nodes has been exceeded. Try restricting the graph."
        end

        introspect(it)
      end
    end
  end

  def get_associated_objects(obj, association_name)
    obj
      .send(association_name)
      .then { |associated_objects| load_association(associated_objects) }
  end

  def load_association(associated_objects)
    Array(
      if associated_objects.is_a?(ActiveRecord::Relation)
        associated_objects.strict_loading!(false)
      else
        associated_objects
      end
    )
  end

  def order_nodes(*nodes)
    nodes.sort_by do |node|
      @node_order.index(node.class.name.underscore) || Float::INFINITY
    end
  end

  def node_link(obj)
    "/inspect/graph/#{obj.class.name.underscore.pluralize}/#{obj.id}"
  end

  def node_name(obj)
    klass = obj.class.name.underscore
    "#{klass}-#{obj.id}"
  end

  def class_text_for_obj(obj)
    obj.class.name.underscore + (obj.in?(@focus) ? "_focused" : "")
  end

  def node_display_name(obj)
    klass = obj.class.name.underscore.humanize
    "#{klass} #{obj.id}"
  end

  def non_breaking_text(text)
    # Insert non-breaking spaces and hyphens to prevent Mermaid from breaking the line
    text.gsub(" ", "&nbsp;").gsub("-", "#8209;")
  end

  def escape_special_chars(text)
    text.to_s.gsub("@", "\\@")
  end

  def node_text(obj)
    text = "\"#{node_display_name(obj)}"

    unless @clickable
      command = "#{obj.class.to_s.classify}.find(#{obj.id})"
      text +=
        "<br><span style=\"font-size:10px\"><i>#{non_breaking_text(command)}</i></span>"
      command =
        "puts GraphRecords.new.graph(#{obj.class.name.underscore}: #{obj.id})"
      text +=
        "<br><span style=\"font-size:10px\"><i>#{non_breaking_text(command)}</i></span>"
    end

    if DETAIL_WHITELIST.key?(obj.class.name.underscore.to_sym)
      DETAIL_WHITELIST[obj.class.name.underscore.to_sym].each do |detail|
        value = obj.send(detail)
        name = detail.to_s
        detail_text = "#{name}: #{escape_special_chars(value)}"
        text +=
          "<br><span style=\"font-size:14px\">#{non_breaking_text(detail_text)}</span>"
      end
    end

    "#{text}\""
  end

  def node_with_class(obj)
    "#{node_name(obj)}[#{node_text(obj)}]:::#{class_text_for_obj(obj)}"
  end
end
