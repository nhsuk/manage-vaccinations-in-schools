# frozen_string_literal: true

module PDSExperiments
  class PDSExperimentSearcher
    class << self
      SEARCH_FIELDS = %w[
        _fuzzy-match
        _exact-match
        _history
        _max-results
        family
        given
        gender
        birthdate
        death-date
        email
        phone
        address-postalcode
        general-practitioner
      ].freeze

      def baseline_search(patient, include_gender: false)
        # Non-fuzzy search with history
        query = {
          "family" => patient.family_name,
          "given" => patient.given_name,
          "birthdate" => "eq#{patient.date_of_birth}",
          "address-postalcode" => patient.address_postcode,
          "_history" => true
        }.compact_blank

        if include_gender && %w[male female].include?(patient.gender_code)
          query["gender"] = patient.gender_code
        end

        query.compact_blank!

        results = search_pds_api(query).body
        if results["total"].zero?
          raise NHS::PDS::PatientNotFound, "No patient found"
        end

        PDS::Patient.send(
          :from_pds_fhir_response,
          results["entry"].first["resource"]
        )
      end

      def non_fuzzy_search_without_history(patient)
        query = {
          "family" => patient.family_name,
          "given" => patient.given_name,
          "birthdate" => "eq#{patient.date_of_birth}",
          "address-postalcode" => patient.address_postcode,
          "_fuzzy-match" => false,
          "_history" => false
        }.compact_blank

        results = search_pds_api(query).body
        if results["total"].zero?
          raise NHS::PDS::PatientNotFound, "No patient found"
        end

        PDS::Patient.send(
          :from_pds_fhir_response,
          results["entry"].first["resource"]
        )
      end

      def fuzzy_search_without_history(patient)
        query = {
          "family" => patient.family_name,
          "given" => patient.given_name,
          "birthdate" => "eq#{patient.date_of_birth}",
          "address-postalcode" => patient.address_postcode,
          "_fuzzy-match" => true,
          "_history" => false
        }.compact_blank

        results = search_pds_api(query).body
        if results["total"].zero?
          raise NHS::PDS::PatientNotFound, "No patient found"
        end

        PDS::Patient.send(
          :from_pds_fhir_response,
          results["entry"].first["resource"]
        )
      end

      def fuzzy_search_with_history(patient)
        # Fuzzy search always includes history
        query = {
          "family" => patient.family_name,
          "given" => patient.given_name,
          "birthdate" => "eq#{patient.date_of_birth}",
          "address-postalcode" => patient.address_postcode,
          "_fuzzy-match" => true
        }.compact_blank

        results = search_pds_api(query).body
        if results["total"].zero?
          raise NHS::PDS::PatientNotFound, "No patient found"
        end

        PDS::Patient.send(
          :from_pds_fhir_response,
          results["entry"].first["resource"]
        )
      end

      def wildcard_search(
        patient:,
        include_gender: false,
        include_history: true,
        surname: true,
        given_name: true,
        postcode: true
      )
        query = {
          "birthdate" => "eq#{patient.date_of_birth}",
          "_fuzzy-match" => false,
          "_history" => include_history
        }

        query["family"] = if surname
          "#{patient.family_name&.first(3)}*"
        else
          patient.family_name
        end

        query["given"] = if given_name
          "#{patient.given_name&.first(3)}*"
        else
          patient.given_name
        end

        query["address-postalcode"] = if postcode
          "#{patient.address_postcode&.first(2)}*"
        else
          patient.address_postcode
        end

        if include_gender && %w[male female].include?(patient.gender_code)
          query["gender"] = patient.gender_code
        end

        query.compact_blank!

        results = search_pds_api(query).body
        if results["total"].zero?
          raise NHS::PDS::PatientNotFound, "No patient found"
        end

        PDS::Patient.send(
          :from_pds_fhir_response,
          results["entry"].first["resource"]
        )
      end

      def exact_search(patient, include_history: false)
        query = {
          "family" => patient.family_name,
          "given" => patient.given_name,
          "birthdate" => "eq#{patient.date_of_birth}",
          "address-postalcode" => patient.address_postcode,
          "_exact-match" => true,
          "_history" => include_history
        }.compact_blank

        results = search_pds_api(query).body
        if results["total"].zero?
          raise NHS::PDS::PatientNotFound, "No patient found"
        end

        PDS::Patient.send(
          :from_pds_fhir_response,
          results["entry"].first["resource"]
        )
      end

      def cascading_search_1(patient, experiment_name)
        steps = [
          {
            name: :baseline,
            run: -> { baseline_search(patient) },
            retry_on: [NHS::PDS::PatientNotFound]
          },
          {
            name: :fuzzy_with_history,
            run: -> { fuzzy_search_with_history(patient) },
            retry_on: [NHS::PDS::TooManyMatches]
          },
          {
            name: :fuzzy_without_history,
            run: -> { fuzzy_search_without_history(patient) },
            retry_on: []
          }
        ]

        steps.each do |step|
          puts "Running step: #{step[:name]}"
          increment_step_counter(experiment_name, step[:name], "reached")
          begin
            result = step[:run].call
            if result.present?
              increment_step_counter(experiment_name, step[:name], "successful")
              return result
            end
          rescue StandardError => e
            increment_step_counter(
              experiment_name,
              step[:name],
              "failed_with_#{e.class.name.demodulize.underscore}"
            )
            raise e unless step[:retry_on].any? { |err| e.is_a?(err) }
          end
        end

        increment_step_counter(experiment_name, "exhausted_all_steps", "total")
        nil
      end

      def cascading_search_2(patient, experiment_name)
        steps = [
          {
            name: :baseline,
            run: -> { baseline_search(patient) },
            retry_on: [NHS::PDS::PatientNotFound]
          },
          {
            name: :wildcard_postcode,
            run: -> do
              wildcard_search(
                patient: patient,
                include_gender: false,
                include_history: true,
                surname: false,
                given_name: false,
                postcode: true
              )
            end,
            retry_on: [NHS::PDS::PatientNotFound, NHS::PDS::TooManyMatches]
          },
          {
            name: :wildcard_given_name,
            run: -> do
              wildcard_search(
                patient: patient,
                include_gender: false,
                include_history: true,
                surname: false,
                given_name: true,
                postcode: false
              )
            end,
            retry_on: [NHS::PDS::PatientNotFound, NHS::PDS::TooManyMatches]
          },
          {
            name: :wildcard_surname,
            run: -> do
              wildcard_search(
                patient: patient,
                include_gender: false,
                include_history: true,
                surname: true,
                given_name: false,
                postcode: false
              )
            end,
            retry_on: []
          }
        ]

        steps.each do |step|
          puts "Running step: #{step[:name]}"
          increment_step_counter(experiment_name, step[:name], "reached")
          begin
            result = step[:run].call
            if result.present?
              increment_step_counter(experiment_name, step[:name], "successful")
              return result
            end
          rescue StandardError => e
            increment_step_counter(
              experiment_name,
              step[:name],
              "failed_with_#{e.class.name.demodulize.underscore}"
            )
            raise e unless step[:retry_on].any? { |err| e.is_a?(err) }
          end
        end

        increment_step_counter(experiment_name, "exhausted_all_steps", "total")
        nil
      end

      def cascading_search_3(patient, experiment_name)
        steps = [
          {
            name: :baseline,
            run: -> { baseline_search(patient, include_gender: true) },
            retry_on: [NHS::PDS::PatientNotFound]
          },
          {
            name: :wildcard_surname,
            run: -> do
              wildcard_search(
                patient: patient,
                include_gender: true,
                include_history: true,
                surname: true,
                given_name: false,
                postcode: false
              )
            end,
            retry_on: [NHS::PDS::PatientNotFound, NHS::PDS::TooManyMatches]
          },
          {
            name: :wildcard_given_name,
            run: -> do
              wildcard_search(
                patient: patient,
                include_gender: true,
                include_history: true,
                surname: false,
                given_name: true,
                postcode: false
              )
            end,
            retry_on: [NHS::PDS::PatientNotFound, NHS::PDS::TooManyMatches]
          },
          {
            name: :wildcard_postcode,
            run: -> do
              wildcard_search(
                patient: patient,
                include_gender: true,
                include_history: true,
                surname: false,
                given_name: false,
                postcode: true
              )
            end,
            retry_on: []
          }
        ]

        steps.each do |step|
          puts "Running step: #{step[:name]}"
          increment_step_counter(experiment_name, step[:name], "reached")
          begin
            result = step[:run].call
            if result.present?
              increment_step_counter(experiment_name, step[:name], "successful")
              return result
            end
          rescue StandardError => e
            increment_step_counter(
              experiment_name,
              step[:name],
              "failed_with_#{e.class.name.demodulize.underscore}"
            )
            raise e unless step[:retry_on].any? { |err| e.is_a?(err) }
          end
        end

        increment_step_counter(experiment_name, "exhausted_all_steps", "total")
        nil
      end

      def cascading_search_4(patient, experiment_name)
        steps = [
          {
            name: :baseline,
            run: -> { baseline_search(patient) },
            retry_on: [NHS::PDS::PatientNotFound]
          },
          {
            name: :wildcard_surname,
            run: -> do
              wildcard_search(
                patient: patient,
                include_gender: false,
                include_history: true,
                surname: true,
                given_name: false,
                postcode: false
              )
            end,
            retry_on: [NHS::PDS::PatientNotFound, NHS::PDS::TooManyMatches]
          },
          {
            name: :wildcard_given_name,
            run: -> do
              wildcard_search(
                patient: patient,
                include_gender: false,
                include_history: true,
                surname: false,
                given_name: true,
                postcode: false
              )
            end,
            retry_on: [NHS::PDS::PatientNotFound, NHS::PDS::TooManyMatches]
          },
          {
            name: :wildcard_postcode,
            run: -> do
              wildcard_search(
                patient: patient,
                include_gender: false,
                include_history: true,
                surname: false,
                given_name: false,
                postcode: true
              )
            end,
            retry_on: [NHS::PDS::PatientNotFound]
          },
          {
            name: :fuzzy_with_history,
            run: -> { fuzzy_search_with_history(patient) },
            retry_on: [NHS::PDS::TooManyMatches]
          },
          {
            name: :fuzzy_without_history,
            run: -> { fuzzy_search_with_history(patient) },
            retry_on: []
          }
        ]

        steps.each do |step|
          puts "Running step: #{step[:name]}"
          increment_step_counter(experiment_name, step[:name], "reached")
          begin
            result = step[:run].call
            if result.present?
              increment_step_counter(experiment_name, step[:name], "successful")
              return result
            end
          rescue StandardError => e
            increment_step_counter(
              experiment_name,
              step[:name],
              "failed_with_#{e.class.name.demodulize.underscore}"
            )
            raise e unless step[:retry_on].any? { |err| e.is_a?(err) }
          end
        end

        increment_step_counter(experiment_name, "exhausted_all_steps", "total")
        nil
      end

      def cascading_search_5(patient, experiment_name)
        puts "Running step: baseline"
        increment_step_counter(experiment_name, :baseline, "reached")

        begin
          result = baseline_search(patient)
          if result.present?
            increment_step_counter(experiment_name, :baseline, "successful")
            return result
          end
        rescue NHS::PDS::PatientNotFound
          increment_step_counter(
            experiment_name,
            :baseline,
            "failed_with_patient_not_found"
          )
          return handle_fuzzy_with_history_branch(patient, experiment_name)
        rescue NHS::PDS::TooManyMatches
          increment_step_counter(
            experiment_name,
            :baseline,
            "failed_with_too_many_matches"
          )
          return(
            handle_non_fuzzy_search_without_history(patient, experiment_name)
          )
        rescue StandardError => e
          raise e
        end
        nil
      end

      private

      def handle_non_fuzzy_search_without_history(patient, experiment_name)
        puts "Running step: non_fuzzy_without_history"
        increment_step_counter(
          experiment_name,
          :non_fuzzy_without_history,
          "reached"
        )

        begin
          result = non_fuzzy_search_without_history(patient)
          if result.present?
            increment_step_counter(
              experiment_name,
              :non_fuzzy_without_history,
              "successful"
            )
            return result
          end
        rescue NHS::PDS::PatientNotFound, NHS::PDS::TooManyMatches => e
          increment_step_counter(
            experiment_name,
            :non_fuzzy_without_history,
            "failed_with_#{e.class.name.demodulize.underscore}"
          )
          nil
        rescue StandardError => e
          raise e
        end
        nil
      end

      def handle_fuzzy_with_history_branch(patient, experiment_name)
        puts "Running step: fuzzy_with_history"
        increment_step_counter(experiment_name, :fuzzy_with_history, "reached")

        begin
          result = fuzzy_search_with_history(patient)
          if result.present?
            increment_step_counter(
              experiment_name,
              :fuzzy_with_history,
              "successful"
            )
            return result
          end
        rescue NHS::PDS::PatientNotFound
          increment_step_counter(
            experiment_name,
            :fuzzy_with_history,
            "failed_with_patient_not_found"
          )
          return handle_wildcard_branch(patient, experiment_name)
        rescue NHS::PDS::TooManyMatches
          increment_step_counter(
            experiment_name,
            :fuzzy_with_history,
            "failed_with_too_many_matches"
          )
          return handle_fuzzy_without_history_branch(patient, experiment_name)
        rescue StandardError => e
          raise e
        end
        nil
      end

      def handle_fuzzy_without_history_branch(patient, experiment_name)
        puts "Running step: fuzzy_without_history"
        increment_step_counter(
          experiment_name,
          :fuzzy_without_history,
          "reached"
        )

        begin
          result = fuzzy_search_without_history(patient)
          if result.present?
            increment_step_counter(
              experiment_name,
              :fuzzy_without_history,
              "successful"
            )
            return result
          end
        rescue NHS::PDS::PatientNotFound, NHS::PDS::TooManyMatches => e
          increment_step_counter(
            experiment_name,
            :fuzzy_without_history,
            "failed_with_#{e.class.name.demodulize.underscore}"
          )
          return handle_wildcard_branch(patient, experiment_name)
        rescue StandardError => e
          raise e
        end
        nil
      end

      def handle_wildcard_branch(patient, experiment_name)
        steps = [
          {
            name: :wildcard_postcode,
            run: -> do
              wildcard_search(
                patient: patient,
                include_gender: false,
                include_history: true,
                surname: false,
                given_name: false,
                postcode: true
              )
            end,
            retry_on: [NHS::PDS::PatientNotFound, NHS::PDS::TooManyMatches]
          },
          {
            name: :wildcard_given_name,
            run: -> do
              wildcard_search(
                patient: patient,
                include_gender: false,
                include_history: true,
                surname: false,
                given_name: true,
                postcode: false
              )
            end,
            retry_on: [NHS::PDS::PatientNotFound, NHS::PDS::TooManyMatches]
          },
          {
            name: :wildcard_surname,
            run: -> do
              wildcard_search(
                patient: patient,
                include_gender: false,
                include_history: true,
                surname: true,
                given_name: false,
                postcode: false
              )
            end,
            retry_on: []
          }
        ]

        steps.each do |step|
          puts "Running step: #{step[:name]}"
          increment_step_counter(experiment_name, step[:name], "reached")
          begin
            result = step[:run].call
            if result.present?
              increment_step_counter(experiment_name, step[:name], "successful")
              return result
            end
          rescue StandardError => e
            increment_step_counter(
              experiment_name,
              step[:name],
              "failed_with_#{e.class.name.demodulize.underscore}"
            )
            raise e unless step[:retry_on].any? { |err| e.is_a?(err) }
          end
        end

        increment_step_counter(experiment_name, "exhausted_all_steps", "total")
        nil
      end

      def search_pds_api(attributes)
        if (missing_attrs = (attributes.keys.map(&:to_s) - SEARCH_FIELDS)).any?
          raise "Unrecognised attributes: #{missing_attrs.join(", ")}"
        end

        response =
          NHS::API.connection.get(
            "personal-demographics/FHIR/R4/Patient",
            attributes
          )

        if is_error?(response, "TOO_MANY_MATCHES")
          raise NHS::PDS::TooManyMatches
        else
          response
        end
      rescue Faraday::BadRequestError
        raise
      end

      def is_error?(error_or_response, code)
        response =
          if error_or_response.is_a?(Faraday::ClientError)
            JSON.parse(error_or_response.response_body)
          elsif error_or_response.is_a?(Faraday::Response)
            error_or_response.body
          end

        return false if (issues = response["issue"]).blank?

        issues.any? do |issue|
          issue["details"]["coding"].any? { |coding| coding["code"] == code }
        end
      end

      def increment_step_counter(experiment_name, step_name, metric)
        cache_key =
          "pds_experiment:#{experiment_name}:step_#{step_name}_#{metric}"
        Rails.cache.increment(cache_key, 1, expires_in: 7.days, initial: 0)
      end
    end
  end
end
