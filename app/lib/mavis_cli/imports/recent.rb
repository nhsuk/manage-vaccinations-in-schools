# frozen_string_literal: true

module MavisCLI
  module Imports
    class Recent < Dry::CLI::Command
      desc "Show recent patient imports (class and cohort) with stats"

      option :once,
             desc: "Print the table one time",
             default: false,
             type: :boolean
      option :number, desc: "Number of imports to show", type: :integer
      option :organisations, desc: "Organisation ODS code(s)", type: :array
      option :workgroups, desc: "Team workgroup(s)", type: :array
      option :cohort_imports, desc: "Include cohort imports", type: :boolean
      option :class_imports, desc: "Include class imports", type: :boolean
      option :immunisation_imports,
             desc: "Include immunisation imports",
             type: :boolean

      def call(
        once: nil,
        number: nil,
        organisations: nil,
        workgroups: nil,
        cohort_imports: false,
        class_imports: false,
        immunisation_imports: false
      )
        MavisCLI.load_rails

        types =
          determine_import_types(
            cohort_imports:,
            class_imports:,
            immunisation_imports:
          )

        once = true unless $stdin.tty?

        if once
          number ||= 10
          print_imports(imports(number:, organisations:, workgroups:, types:))
          return
        end

        loop do
          lines = number
          lines ||= MavisCLI.terminal_lines

          next_imports =
            imports(number: lines - 5, organisations:, workgroups:, types:)

          $stdout.clear_screen
          puts Time.current
          print_imports(next_imports)

          sleep 30 or break
        end
      end

      private

      def imports(number:, organisations:, workgroups:, types:)
        # Don't limit per type - we need to sort and limit across all types
        all_imports =
          types.flat_map do |import_class|
            query_imports(import_class, organisations:, workgroups:)
          end

        # Sort by created_at DESC across both types
        sorted_imports =
          all_imports.sort_by { |import| -import.created_at.to_i }
        limit = number ? number.to_i : sorted_imports.size
        sorted_imports.take(limit)
      end

      def determine_import_types(
        cohort_imports:,
        class_imports:,
        immunisation_imports:
      )
        show_all =
          [cohort_imports, class_imports, immunisation_imports].all? do
            it == false
          end

        types = []
        types << CohortImport.readonly if cohort_imports || show_all
        types << ClassImport.readonly if class_imports || show_all
        types << ImmunisationImport.readonly if immunisation_imports || show_all

        types
      end

      def query_imports(import_class, organisations:, workgroups:)
        # Build includes based on import class
        includes_hash = { team: :organisation }
        includes_hash[:location] = nil if import_class == ClassImport

        # stree-ignore
        import_class
          .includes(includes_hash)
          .order("#{import_class.table_name}.created_at DESC")
          .then {
            if organisations.present?
              it.joins(team: :organisation).where(
                organisations: {
                  ods_code: organisations
                }
              )
            else
              it
            end
          }
          .then do
          if workgroups.present?
            it.joins(:team).where(team: { workgroup: workgroups })
          else
            it
          end
        end
      end

      def print_imports(imports)
        imports_data =
          imports.map do |import|
            import_type = import.class.to_s.underscore.gsub("_import", "")

            {
              type: import_type,
              id: import.id,
              created_at: import.created_at,
              processed_at: import.processed_at,
              rows: import.rows_count,
              ods: import.team.organisation.ods_code,
              workgroup: import.team.workgroup,
              status: import.status,
              **get_additional_data(import)
            }
          end

        puts TableTennis.new(imports_data, coerce: false, separators: false)
      end

      def get_additional_data(import)
        case import
        when ClassImport
          {
            changesets: import.changesets.count,
            location: import.location&.name
          }.merge(import.changesets.pluck(:status).tally)
        when CohortImport
          {
            changesets: import.changesets.count,
            patients_in_schools: import.patients.select(&:school_id).count
          }.compact.merge(import.changesets.pluck(:status).tally)
        when ImmunisationImport
          {}
        else
          raise ArgumentError, "unsupported import type: #{import.class}"
        end
      end
    end
  end

  register "imports" do |prefix|
    prefix.register "recent", Imports::Recent
  end
end
