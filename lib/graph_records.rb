# frozen_string_literal: true

# Spit out a Mermaid-style graph of records.
#
# Usage:
#  graph = GraphRecords.new.graph(patients: [patient])
#  puts graph
#
class GraphRecords
  # @param focus_config [Hash] Hash of model names to ids to focus on (make bold)
  # @param node_order [Array] Array of model names in order to render nodes
  # @param traversals_config [Hash] Hash of model names to arrays of associations to traverse
  def initialize(
    focus_config: {},
    node_order: %i[class_import cohort_import patient consent parent],
    traversals_config: {}
  )
    @focus_config = focus_config
    @node_order = node_order
    @traversals_config = traversals_config
  end

  # @param objects [Hash] Hash of model name to ids to be graphed
  def graph(**objects)
    @nodes = Set.new
    @edges = Set.new
    @inspected = Set.new
    @focus = @focus_config.map { _1.to_s.classify.constantize.where(id: _2) }

    objects.map do |klass, ids|
      class_name = klass.to_s.singularize
      associated_objects =
        load_association(
          class_name,
          class_name.classify.constantize.where(id: ids)
        )

      @focus += associated_objects

      associated_objects.each do |obj|
        @nodes << obj
        inspect(obj)
      end
    end
    ["flowchart TB"] + render_styles + render_nodes + render_edges
  end

  def traversals
    @traversals ||= {
      patient: %i[parents consents class_imports cohort_imports],
      parent: %i[consents class_imports cohort_imports]
    }.merge(@traversals_config)
  end

  def render_styles
    {
      patient: "fill:#c2e598",
      parent: "fill:#faa0a0",
      consent: "fill:#fffaa0",
      class_import: "fill:#7fd7df",
      cohort_import: "fill:#a2d2ff",
      patient_focused: "fill:#c2e598,stroke:#000,stroke-width:3px",
      parent_focused: "fill:#faa0a0,stroke:#000,stroke-width:3px"
    }.with_indifferent_access
      .slice(*@nodes.map { class_text_for_obj(it) })
      .map { |klass, style| "  classDef #{klass} #{style}" }
  end

  def render_nodes
    @nodes.to_a.map { "  #{node_with_class(it)}" }
  end

  def render_edges
    @edges.map { |from, to| "  #{node_name(from)} --> #{node_name(to)}" }
  end

  def inspect(obj)
    associations_list = traversals[obj.class.name.underscore.to_sym]
    return if associations_list.blank?

    return if @inspected.include?(obj)
    @inspected << obj

    associations_list.each do
      get_associated_objects(obj, it).each do
        @nodes << it
        @edges << order_nodes(obj, it)

        inspect(it)
      end
    end
  end

  def get_associated_objects(obj, association_name)
    obj
      .send(association_name)
      .then do |associated_objects|
        load_association(association_name, associated_objects)
      end
  end

  def load_association(association_name, associated_objects)
    if respond_to?("#{association_name}_loader")
      send("#{association_name}_loader", associated_objects)
    else
      associated_objects
    end
  end

  def parents_loader(parents)
    parents.includes(:consents, :class_imports, :cohort_imports)
  end

  def patients_loader(patients)
    patients.includes(:parents, :class_imports, :cohort_imports)
  end

  def order_nodes(*nodes)
    nodes.sort_by { @node_order.index(it.class.name.underscore.to_sym) }
  end

  def node_name(obj)
    klass = obj.class.name.underscore
    "#{klass}-#{obj.id}"
  end

  def node_with_class(obj)
    "#{node_name(obj)}:::#{class_text_for_obj(obj)}"
  end

  def class_text_for_obj(obj)
    obj.class.name.underscore + (obj.in?(@focus) ? "_focused" : "")
  end
end
