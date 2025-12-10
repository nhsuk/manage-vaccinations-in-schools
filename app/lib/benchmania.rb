# frozen_string_literal: true

module Benchmania
  def self.included(base)
    base.extend ClassMethods
  end

  def self.call
    reset
    yield
    @log.each { add_result(*it) }
    @runs ||= []
    @runs << {
      run_time: Time.current,
      totals: results,
      nested_totals: nested_results
    }
    runs.last
  end

  def self.runs
    @runs || []
  end

  def self.results_table(run = runs.last)
    totals_list =
      run[:totals]
        .sort_by { _2[:time] }
        .reverse
        .map do |method, results|
          {
            method: method,
            calls: results[:calls],
            time: results[:time],
            overhead: results[:overhead]
          }
        end

    puts TableTennis.new(totals_list)
  end

  def self.nested_results_table(run = runs.last)
    nested_totals_list = generate_nested_totals(run[:nested_totals])
    puts TableTennis.new(nested_totals_list)
  end

  private

  def self.generate_nested_totals(results, depth = 0)
    results.flat_map do |method, result|
      [
        {
          # TableTennis strips leading spaces, so use non-breaking space
          method:
            ("\u00A0" * (2 * depth)) + (depth > 0 ? "└ #{method}" : method),
          calls: result[:calls],
          time: result[:time],
          overhead: result[:overhead]
        }
      ] + generate_nested_totals(result[:nested_calls], depth + 1)
    end
  end

  def self.results
    @results ||= Hash.new { _1[_2] = { calls: 0, time: 0, overhead: 0 } }
  end

  def self.nested_hash
    Hash.new do
      _1[_2] = { calls: 0, time: 0, overhead: 0, nested_calls: nested_hash }
    end
  end

  def self.nested_results
    @nested_results ||= nested_hash
  end

  def self.reset
    @results = nil
    @nested_results = nil
    @trail = []
    @log = []
  end

  def self.set_decorating
    @decorating = true
  end

  def self.are_decorating?
    @decorating == true
  end

  def self.clear_decorating
    @decorating = false
  end

  def self.sample(label)
    ret = nil
    time_elapsed = nil
    total_time =
      Benchmark.realtime do
        @trail << label
        time_elapsed = Benchmark.realtime { ret = yield }
        @log << [@trail.dup, time_elapsed]
        @trail.pop
      end
    @log[-1] << total_time
    ret
  end

  def self.add_result(trail, time_elapsed, total_time)
    overhead = total_time - time_elapsed
    results[trail.last][:calls] += 1
    results[trail.last][:time] += time_elapsed
    results[trail.last][:overhead] += overhead

    nested_path = trail[0..-2].flat_map { [it, :nested_calls] } + [trail.last]
    nested_results.dig(*nested_path)[:calls] += 1
    nested_results.dig(*nested_path)[:time] += time_elapsed
    nested_results.dig(*nested_path)[:overhead] += overhead
  end

  module ClassMethods
    def benchmania_sample
      ::Benchmania.set_decorating
    end

    def method_added(name)
      return super unless ::Benchmania.are_decorating?
      ::Benchmania.clear_decorating

      @benchmania_methods ||= {}
      @benchmania_methods[name] = instance_method(name)

      # TODO: Can this go into an `extended` block maybe?
      class << self
        attr_accessor :benchmania_methods
      end

      class_eval <<-METHOD, __FILE__, __LINE__ + 1
        def #{name}(...)
          Benchmania.sample("#{self.name}##{name}") do
            self.class.benchmania_methods[#{name.inspect}].bind(self).call(...)
          end
        end
      METHOD
    end

    def singleton_method_added(name)
      return super unless ::Benchmania.are_decorating?
      ::Benchmania.clear_decorating

      method_name = :"self.#{name}"
      @benchmania_methods ||= {}
      @benchmania_methods[method_name] = singleton_method(name)

      # TODO: Can this go into an `extended` block maybe?
      class << self
        attr_accessor :benchmania_methods
      end

      class_eval <<-METHOD, __FILE__, __LINE__ + 1
        def self.#{name}(...)
          Benchmania.sample("#{self.name}.#{name}") do
            benchmania_methods[#{method_name.inspect}].call(...)
          end
        end
      METHOD
    end
  end
end
