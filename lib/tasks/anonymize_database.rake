# lib/tasks/anonymize_database.rake
require 'openssl'
require 'digest'

namespace :data_masking do
  desc "Anonymize all PII data in the database using HMAC-based hashing"
  task anonymize_all: :environment do
    # Generate a random salt
    salt = SecureRandom.hex(32)
    puts "=" * 80
    puts "STARTING FULL DATABASE ANONYMIZATION"
    puts "=" * 80
    puts "Generated salt: #{salt[0..7]}... (truncated for display)"
    puts "Timestamp: #{Time.now}"
    puts "\nIMPORTANT: Store this salt securely if you need to verify hashes later"
    puts "=" * 80

    overall_start = Time.now
    batch_size = 10000

    # Enable pgcrypto extension if not already enabled
    ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS pgcrypto")
    
    begin
      # Archive Reasons
      TableAnonymizer.anonymize_table("archive_reasons", [
        { name: "type", type: :text, length: 30 },
        { name: "other_details", type: :text, length: 100 }
      ], salt, batch_size) if ActiveRecord::Base.connection.table_exists?("archive_reasons")

      # Consent Forms
      TableAnonymizer.anonymize_table("consent_forms", [
        { name: "given_name", type: :text, length: 50 },
        { name: "family_name", type: :text, length: 50 },
        { name: "date_of_birth", type: :date },
        { name: "address_line_1", type: :text, length: 50 },
        { name: "address_line_2", type: :text, length: 50 },
        { name: "address_town", type: :text, length: 50 },
        { name: "address_postcode", type: :postcode },
        { name: "gender_code", type: :enum, length: 10 },
        # { name: "health_answers", type: :drop, length: 200 }, TODO should be dropped but cant due to nonull constraint, so needs to be anonymized differently
        { name: "parent_email", type: :email },
        { name: "parent_full_name", type: :text, length: 50 },
        { name: "parent_phone", type: :phone },
        { name: "parent_relationship_other_name", type: :text, length: 50 },
        { name: "parent_relationship_type", type: :text, length: 30 },
        { name: "preferred_given_name", type: :text, length: 50 },
        { name: "preferred_family_name", type: :text, length: 50 },
        { name: "nhs_number", type: :nhs_number },
        { name: "notes", type: :text, length: 200 }
      ], salt, batch_size)

      # Consents
      TableAnonymizer.anonymize_table("consents", [
        { name: "notes", type: :text, length: 200 }
      ], salt, batch_size)

      # Gillick Assessments
      TableAnonymizer.anonymize_table("gillick_assessments", [
        { name: "notes", type: :text, length: 200 }
      ], salt, batch_size) if ActiveRecord::Base.connection.table_exists?("gillick_assessments")

      # Identity Checks
      TableAnonymizer.anonymize_table("identity_checks", [
        { name: "confirmed_by_other_name", type: :text, length: 50 },
        { name: "confirmed_by_other_relationship", type: :text, length: 50 }
      ], salt, batch_size) if ActiveRecord::Base.connection.table_exists?("identity_checks")

      # Locations
      TableAnonymizer.anonymize_table("locations", [
        { name: "name", type: :text, length: 100 }
      ], salt, batch_size)

      # Notes
      TableAnonymizer.anonymize_table("notes", [
        { name: "body", type: :text, length: 200 }
      ], salt, batch_size) if ActiveRecord::Base.connection.table_exists?("notes")

      # Parent Relationships
      TableAnonymizer.anonymize_table("parent_relationships", [
        { name: "type", type: :text, length: 30 },
        { name: "other_name", type: :text, length: 50 }
      ], salt, batch_size) if ActiveRecord::Base.connection.table_exists?("parent_relationships")

      # Parents
      TableAnonymizer.anonymize_table("parents", [
        { name: "full_name", type: :text, length: 50 },
        { name: "email", type: :email },
        { name: "phone", type: :phone },
        { name: "contact_method_type", type: :text, length: 30 }
      ], salt, batch_size)

      # Patients
      TableAnonymizer.anonymize_table("patients", [
        { name: "given_name", type: :text, length: 50 },
        { name: "family_name", type: :text, length: 50 },
        { name: "date_of_birth", type: :date },
        { name: "nhs_number", type: :nhs_number },
        { name: "address_line_1", type: :text, length: 50 },
        { name: "address_line_2", type: :text, length: 50 },
        { name: "address_town", type: :text, length: 50 },
        { name: "address_postcode", type: :postcode },
        { name: "gender_code", type: :enum, length: 10 },
        { name: "registration", type: :text, length: 50 },
        { name: "date_of_death", type: :date },
        # { name: "pending_changes", type: :drop, length: 100 }, should be anonymised still
        { name: "preferred_given_name", type: :text, length: 50 },
        { name: "preferred_family_name", type: :text, length: 50 }
      ], salt, batch_size)

      # PDS Search Results
      TableAnonymizer.anonymize_table("pds_search_results", [
        { name: "nhs_number", type: :nhs_number }
      ], salt, batch_size) if ActiveRecord::Base.connection.table_exists?("pds_search_results")

      # Pre Screenings
      TableAnonymizer.anonymize_table("pre_screenings", [
        { name: "notes", type: :text, length: 200 }
      ], salt, batch_size) if ActiveRecord::Base.connection.table_exists?("pre_screenings")

      # Reporting API Vaccination Events (large table with many columns)
      TableAnonymizer.anonymize_table("reporting_api_vaccination_events", [
        { name: "patient_address_town", type: :text, length: 50 },
        { name: "patient_address_postcode", type: :postcode },
        { name: "patient_gender_code", type: :text, length: 10 },
        { name: "patient_date_of_birth", type: :date },
        { name: "patient_school_name", type: :text, length: 100 },
        { name: "patient_school_address_postcode", type: :postcode },
        { name: "patient_school_gias_local_authority_code", type: :text, length: 10 },
        { name: "patient_school_type", type: :text, length: 50 },
        { name: "patient_school_local_authority_mhclg_code", type: :text, length: 10 },
        { name: "patient_school_local_authority_short_name", type: :text, length: 50 },
        { name: "patient_local_authority_from_postcode_mhclg_code", type: :text, length: 10 },
        { name: "patient_local_authority_from_postcode_short_name", type: :text, length: 50 },
        { name: "location_name", type: :text, length: 100 },
        { name: "location_address_town", type: :text, length: 50 },
        { name: "location_address_postcode", type: :postcode },
        { name: "location_type", type: :text, length: 30 },
        { name: "location_local_authority_mhclg_code", type: :text, length: 10 },
        { name: "location_local_authority_short_name", type: :text, length: 50 },
        { name: "vaccination_record_outcome", type: :text, length: 30 }
      ], salt, batch_size) if ActiveRecord::Base.connection.table_exists?("reporting_api_vaccination_events")

      # School Move Log Entries
      if ActiveRecord::Base.connection.table_exists?("school_move_log_entries") &&
         ActiveRecord::Base.connection.column_exists?("school_move_log_entries", "home_educated")
        # home_educated is likely boolean, but if it needs anonymization:
        # TableAnonymizer.anonymize_table("school_move_log_entries", [
        #   { name: "home_educated", type: :text, length: 10 }
        # ], salt, batch_size)
      end

      # School Moves
      if ActiveRecord::Base.connection.table_exists?("school_moves") &&
         ActiveRecord::Base.connection.column_exists?("school_moves", "home_educated")
        # home_educated is likely boolean, skip unless it's text
      end

      # Triages
      TableAnonymizer.anonymize_table("triages", [
        { name: "status", type: :enum, length: 30 },
        { name: "notes", type: :text, length: 200 }
      ], salt, batch_size) if ActiveRecord::Base.connection.table_exists?("triages")

      # Users
      TableAnonymizer.anonymize_table("users", [
        { name: "email", type: :email },
        { name: "given_name", type: :text, length: 50 },
        { name: "family_name", type: :text, length: 50 },
        { name: "current_sign_in_ip", type: :ip },
        { name: "last_sign_in_ip", type: :ip },
        { name: "sign_in_count", type: :integer }
      ], salt, batch_size)

      # Vaccination Records
      TableAnonymizer.anonymize_table("vaccination_records", [
        { name: "outcome", type: :enum, length: 30 },
        { name: "notes", type: :text, length: 200 },
        { name: "dose_sequence", type: :integer, length: 10 },
        { name: "performed_by_given_name", type: :text, length: 50 },
        { name: "performed_by_family_name", type: :text, length: 50 },
        { name: "location_name", type: :text, length: 100 },
      # { name: "pending_changes", type: :drop, length: 100 } TODO
      ], salt, batch_size)

      # TODO Audits table - special handling for audited_changes JSONB
      # TableAnonymizer.anonymize_table("audits", [
      #   { name: "audited_changes", type: drop, length: 100 }
      # ], salt, batch_size) if ActiveRecord::Base.connection.table_exists?("audits")

      overall_duration = Time.now - overall_start

      puts "\n" + "=" * 80
      puts "ANONYMIZATION COMPLETED SUCCESSFULLY"
      puts "=" * 80
      puts "Total duration: #{overall_duration.round(2)} seconds"
      puts "Salt used: #{salt}"
      puts "\nIMPORTANT: Store this salt securely if you need to verify hashes later"
      puts "=" * 80

    rescue StandardError => e
      puts "\n" + "!" * 80
      puts "ERROR DURING ANONYMIZATION"
      puts "!" * 80
      puts "Error: #{e.message}"
      puts e.backtrace.first(10).join("\n")
      raise
    end
  end
end

class TableAnonymizer
  def self.anonymize_table(table_name, columns, salt, batch_size)
    conn = ActiveRecord::Base.connection

    # Count total records
    total_count = conn.execute("SELECT COUNT(*) FROM #{table_name}").first["count"].to_i

    return if total_count == 0

    puts "\n" + "-" * 80
    puts "Anonymizing #{table_name} (#{total_count} records)"
    puts "-" * 80

    start_time = Time.now
    processed = 0

    loop do
      # Build SET clause
      set_clause = columns.map do |col_info|
        col_name = col_info[:name]
        hash_length = col_info[:length] || 50

        case col_info[:type]
        when :text
          "#{col_name} = LEFT(encode(hmac(COALESCE(#{col_name}::text, ''), '#{conn.quote_string(salt)}', 'sha256'), 'hex'), #{hash_length})"
        when :email
          # Keep email format: hash@example.com
          "#{col_name} = LEFT(encode(hmac(COALESCE(#{col_name}, ''), '#{conn.quote_string(salt)}', 'sha256'), 'hex'), 20) || '@example.com'"
        when :phone
          # Generate consistent 11-digit phone number from hash
          "#{col_name} = '0' || LPAD(SUBSTRING(encode(hmac(COALESCE(#{col_name}, ''), '#{conn.quote_string(salt)}', 'sha256'), 'hex'), 1, 10), 10, '0')"
        when :postcode
          # Generate fake postcode format: AA11 1AA
          # TODO, the code validates postcodes so they must be real postcodes
          nil
        when :nhs_number
          # Generate 10-digit NHS number
          # TODO
        when :date
          # Shift date within the same academic year (September 1 to August 31)
          # Academic year starts Sept 1, so for a date, find its academic year bounds and shift within that
          <<~SQL.strip
            #{col_name} = CASE 
              WHEN #{col_name} IS NOT NULL THEN
                -- Calculate academic year start (Sept 1 of the academic year)
                -- If month >= 9, academic year starts same year, else previous year
                (CASE 
                  WHEN EXTRACT(MONTH FROM #{col_name}) >= 9 
                  THEN make_date(EXTRACT(YEAR FROM #{col_name})::int, 9, 1)
                  ELSE make_date(EXTRACT(YEAR FROM #{col_name})::int - 1, 9, 1)
                END) + 
                -- Add a consistent offset based on hash (0-364 days to stay within academic year)
                (('x' || LEFT(encode(hmac(#{col_name}::text, '#{conn.quote_string(salt)}', 'sha256'), 'hex'), 8))::bit(32)::int % 365) * INTERVAL '1 day'
              ELSE NULL 
            END
          SQL
        when :ip
          # Generate consistent IP from hash (127.x.x.x format for localhost range)
          "#{col_name} = '127.' || ((('x' || SUBSTRING(encode(hmac(COALESCE(#{col_name}::text, ''), '#{conn.quote_string(salt)}', 'sha256'), 'hex'), 1, 2))::bit(8)::int) % 256)::text || '.' || ((('x' || SUBSTRING(encode(hmac(COALESCE(#{col_name}::text, ''), '#{conn.quote_string(salt)}', 'sha256'), 'hex'), 3, 2))::bit(8)::int) % 256)::text || '.' || ((('x' || SUBSTRING(encode(hmac(COALESCE(#{col_name}::text, ''), '#{conn.quote_string(salt)}', 'sha256'), 'hex'), 5, 2))::bit(8)::int) % 256)::text"
        when :integer
          # Generate consistent integer from hash
          "#{col_name} = ('x' || LEFT(encode(hmac(COALESCE(#{col_name}::text, '0'), '#{conn.quote_string(salt)}', 'sha256'), 'hex'), 8))::bit(32)::int"
        when :jsonb
          # JSONB columns are handled separately via anonymize_jsonb_columns method
          nil
        when :enum
          # Generate appropriate enum
          # TODO needs to be handled more intelligently, enums will probably not make sense when swapped or be trivially deduced e.g.
          # gender_code can be deduced when identifying an all boys school and consistency within the session means one can then deduce
          # gender of all others. On the other hand, the triage status only makes sense if it's consistent within the vaccination status.
          nil
        when :drop
          # Drop column
          "#{col_name} = NULL"
        else
          raise "Unknown column type: #{col_info[:type]}"
        end
      end.compact

      return if set_clause.empty?

      sql = <<~SQL
            UPDATE #{table_name}
            SET #{set_clause.join(",\n    ")}
            WHERE id IN (
              SELECT id FROM #{table_name}
              ORDER BY id
              OFFSET #{processed}
              LIMIT #{batch_size}
            )
          SQL

      result = conn.execute(sql)
      rows_updated = result.cmd_tuples

      break if rows_updated == 0

      processed += rows_updated
      progress = (processed.to_f / total_count * 100).round(1)
      puts "  Progress: #{processed}/#{total_count} (#{progress}%)"
    end

    duration = Time.now - start_time
    puts "  ✓ Completed in #{duration.round(2)} seconds"
  end

  # Helper for JSONB anonymization
  def self.anonymize_jsonb_columns(table_name, jsonb_columns, salt, batch_size)
    return unless ActiveRecord::Base.connection.table_exists?(table_name)

    model_class = table_name.classify.constantize rescue nil
    return unless model_class

    total_count = model_class.count
    return if total_count == 0

    puts "\n" + "-" * 80
    puts "Anonymizing JSONB columns in #{table_name} (#{total_count} records)"
    puts "-" * 80

    start_time = Time.now
    processed = 0

    model_class.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |record|
        jsonb_columns.each do |col_name|
          next if record[col_name].blank?

          anonymized = anonymize_hash_recursively(record[col_name], salt)
          record.update_column(col_name, anonymized) if anonymized != record[col_name]
        end
      end

      processed += batch.size
      progress = (processed.to_f / total_count * 100).round(1)
      puts "  Progress: #{processed}/#{total_count} (#{progress}%)"
    end

    duration = Time.now - start_time
    puts "  ✓ Completed in #{duration.round(2)} seconds"
  end

  def self.anonymize_hash_recursively(obj, salt)
    case obj
    when Hash
      obj.transform_values { |v| anonymize_hash_recursively(v, salt) }
    when Array
      obj.map { |v| anonymize_hash_recursively(v, salt) }
    when String
      return obj if obj.nil? || obj == ""
      # Use OpenSSL HMAC for consistency, truncate to reasonable length
      OpenSSL::HMAC.hexdigest('sha256', salt, obj)[0..31]
    when Integer, Float, TrueClass, FalseClass, NilClass
      # Keep these types as-is
      obj
    else
      # For any other type, convert to string and hash
      OpenSSL::HMAC.hexdigest('sha256', salt, obj.to_s)[0..31]
    end
  end
end
