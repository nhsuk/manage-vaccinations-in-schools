# frozen_string_literal: true

class VaccineCriteria
  def initialize(vaccine_methods:, without_gelatine:)
    @vaccine_methods = vaccine_methods
    @without_gelatine = without_gelatine
  end

  def self.from_consentable(consentable)
    new(
      vaccine_methods: consentable.vaccine_methods,
      without_gelatine: consentable.without_gelatine
    )
  end

  def self.from_consent_status(consent_status)
    new(
      vaccine_methods: consent_status.vaccine_methods,
      without_gelatine: consent_status.without_gelatine
    )
  end

  def self.from_triage_status(triage_status)
    new(
      vaccine_methods: [triage_status.vaccine_method].compact,
      without_gelatine: triage_status.without_gelatine
    )
  end

  attr_reader :vaccine_methods, :without_gelatine

  def apply(scope)
    scope = scope.where(method: vaccine_methods).order(method_order_node)

    scope = scope.where(contains_gelatine: false) if without_gelatine

    scope
  end

  private

  def method_order_node
    vaccine_methods
      .each_with_index
      .reduce(
        Arel::Nodes::Case.new(Vaccine.arel_table[:method])
      ) { |node, (method, i)| node.when(Vaccine.methods.fetch(method)).then(i) }
  end
end
