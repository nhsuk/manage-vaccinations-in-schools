# lib/tasks/anonymize_child_names.rake
namespace :data_masking do
  desc "Anonymize child first and last names using salted hashing (SQL-based)"
  task anonymize_child_names: :environment do
    # Generate a random salt
    salt = SecureRandom.hex(32)
    puts "Generated salt: #{salt[0..7]}... (truncated for display)"

    # Count total children before anonymization
    total_children = Patient.count
    puts "Starting anonymization of #{total_children} children using SQL with progress tracking..."

    start_time = Time.now
    batch_size = 10000

    begin
      # Enable pgcrypto extension if not already enabled
      ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS pgcrypto")

      processed = 0
      loop do
        # Process in batches using LIMIT
        sql = <<~SQL
          UPDATE patients
          SET
            given_name = LEFT(encode(hmac(given_name, '#{ActiveRecord::Base.connection.quote_string(salt)}', 'sha256'), 'hex'), 5),
            family_name = LEFT(encode(hmac(family_name, '#{ActiveRecord::Base.connection.quote_string(salt)}', 'sha256'), 'hex'), 5),
            updated_at = NOW()
          WHERE id IN (
            SELECT id FROM patients
            ORDER BY id
            OFFSET #{processed}
            LIMIT #{batch_size}
          )
        SQL

        result = ActiveRecord::Base.connection.execute(sql)
        rows_updated = result.cmd_tuples

        break if rows_updated == 0

        processed += rows_updated
        puts "Processed #{processed}/#{total_children} children..."
      end

      end_time = Time.now
      duration = end_time - start_time

      puts "\nAnonymization complete!"
      puts "Successfully anonymized: #{processed} children"
      puts "Duration: #{duration.round(2)} seconds"
      puts "Salt used: #{salt}"
      puts "\nIMPORTANT: Store this salt securely if you need to verify hashes later"
    rescue StandardError => e
      puts "\nError during anonymization: #{e.message}"
      puts e.backtrace.first(5).join("\n")
      raise
    end
  end
end
