# frozen_string_literal: true

namespace :redis do
  desc "Test Redis connectivity and Sidekiq configuration"
  task test: :environment do
    puts "Testing Redis connectivity..."

    begin
      redis_url = ENV["SIDEKIQ_REDIS_URL"] || ENV["REDIS_URL"]
      puts "Connecting to: #{redis_url&.gsub(%r{//.*@}, "//***@")}" # Hide credentials in output

      # Test basic Redis connection
      Sidekiq.redis do |conn|
        result = conn.call("PING")
        puts "✅ Redis PING successful: #{result}"

        # Test basic operations
        test_key = "test:#{Time.current.to_i}"
        conn.call("SET", test_key, "Hello from Redis!")
        value = conn.call("GET", test_key)
        conn.call("DEL", test_key)

        puts "✅ Basic operations working: #{value}"

        # Get Redis info
        info = conn.call("INFO", "server")
        redis_version =
          begin
            info.match(/redis_version:([^\r\n]+)/)[1]
          rescue StandardError
            "unknown"
          end
        puts "✅ Redis version: #{redis_version}"

        # Check if cluster mode is disabled
        begin
          cluster_info = conn.call("CLUSTER", "INFO")
          puts "❌ WARNING: Cluster mode appears to be enabled!"
          puts "   This may cause issues with Sidekiq."
          puts "   Cluster info: #{cluster_info}"
        rescue => e
          if e.message.include?("This instance has cluster support disabled")
            puts "✅ Cluster mode is disabled (good for Sidekiq)"
          else
            puts "ℹ️  Cluster command not available: #{e.message}"
          end
        end
      end

      # Test Sidekiq job enqueueing
      puts "\nTesting Sidekiq job operations..."

      # Check Sidekiq stats
      stats = Sidekiq::Stats.new
      puts "✅ Sidekiq stats accessible"
      puts "   Processed: #{stats.processed}"
      puts "   Failed: #{stats.failed}"
      puts "   Enqueued: #{stats.enqueued}"

      puts "\n✅ All tests passed!"
    rescue => e
      puts "❌ Redis test failed: #{e.message}"
      puts e.backtrace.first(5)
      exit 1
    end
  end

  desc "Show Redis configuration and info"
  task info: :environment do
    begin
      redis_url = ENV["SIDEKIQ_REDIS_URL"] || ENV["REDIS_URL"]
      puts "Redis URL: #{redis_url&.gsub(%r{//.*@}, "//***@")}" # Hide credentials
      puts "Valkey Endpoint: #{ENV["VALKEY_ENDPOINT"]}"
      puts "Valkey Port: #{ENV["VALKEY_PORT"]}"

      Sidekiq.redis do |conn|
        info = conn.call("INFO")

        # Parse and display key information
        info_lines = info.split("\r\n")

        puts "\n=== Redis Server Info ==="
        server_info =
          info_lines.select do |line|
            line.start_with?(
              "redis_version:",
              "redis_mode:",
              "os:",
              "arch_bits:"
            )
          end
        server_info.each { |line| puts line }

        puts "\n=== Memory Info ==="
        memory_info =
          info_lines.select do |line|
            line.start_with?(
              "used_memory_human:",
              "maxmemory_human:",
              "maxmemory_policy:"
            )
          end
        memory_info.each { |line| puts line }

        puts "\n=== Replication Info ==="
        replication_info =
          info_lines.select do |line|
            line.start_with?("role:", "connected_slaves:")
          end
        replication_info.each { |line| puts line }

        puts "\n=== Client Info ==="
        client_info =
          info_lines.select do |line|
            line.start_with?(
              "connected_clients:",
              "client_recent_max_input_buffer:"
            )
          end
        client_info.each { |line| puts line }
      end
    rescue => e
      puts "❌ Failed to get Redis info: #{e.message}"
      exit 1
    end
  end
end
