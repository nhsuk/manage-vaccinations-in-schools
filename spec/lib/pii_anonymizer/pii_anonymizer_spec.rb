# frozen_string_literal: true

require_relative "../../../app/lib/pii_anonymizer/pii_anonymizer"

describe PIIAnonymizer do
  let(:test_config_path) do
    Rails.root.join("spec/fixtures/test_pii_config.yml")
  end

  describe "initialization" do
    it "loads configuration successfully" do
      anonymizer =
        described_class.new(config_path: test_config_path, dry_run: true)
      expect(anonymizer.config).to be_a(Hash)
      expect(anonymizer.dry_run).to be true
    end

    it "raises error for missing config file" do
      expect {
        described_class.new(config_path: "/nonexistent/path.yml")
      }.to raise_error(
        PIIAnonymizer::ConfigurationError,
        /Configuration file not found/
      )
    end
  end

  describe "environment validation" do
    let(:anonymizer) do
      described_class.new(config_path: test_config_path, dry_run: true)
    end

    it "allows test environment" do
      allow(Rails.env).to receive_messages(
        test?: true,
        development?: false,
        production?: false
      )

      expect { anonymizer.send(:validate_environment!) }.not_to raise_error
    end

    it "rejects production environment" do
      allow(Rails.env).to receive_messages(
        test?: false,
        development?: false,
        production?: true
      )

      expect { anonymizer.send(:validate_environment!) }.to raise_error(
        PIIAnonymizer::AnonymizationError
      )
    end
  end

  describe "SQL generation" do
    let(:anonymizer) do
      described_class.new(config_path: test_config_path, dry_run: true)
    end

    it "builds correct UPDATE SQL" do
      updates = { "given_name" => "John", "family_name" => "Doe" }
      sql = anonymizer.send(:build_update_sql, "users", updates)

      expect(sql).to include('UPDATE "users" SET')
      expect(sql).to include('"given_name" = \'John\'')
      expect(sql).to include('"family_name" = \'Doe\'')
    end

    it "properly quotes values to prevent SQL injection" do
      updates = { "given_name" => "O'Connor" }
      sql = anonymizer.send(:build_update_sql, "users", updates)

      expect(sql).to include("'O''Connor'")
    end

    it "generates fake values for fields" do
      fields_config = {
        "given_name" => {
          "faker_method" => "PIIAnonymizer::FakeDataGenerators.first_name"
        }
      }

      updates = anonymizer.send(:build_field_updates, fields_config)
      expect(updates["given_name"]).to be_a(String)
      expect(updates["given_name"].length).to be > 2
    end
  end

  describe "dry run mode" do
    let(:anonymizer) do
      described_class.new(config_path: test_config_path, dry_run: true)
    end

    it "does not execute SQL in dry run mode" do
      expect(ActiveRecord::Base.connection).not_to receive(:execute)

      allow(anonymizer).to receive(:get_table_count).and_return(0)
      anonymizer.anonymize_all!
    end

    it "logs processing information" do
      allow(anonymizer).to receive(:get_table_count).and_return(1)

      log_messages = []
      allow(anonymizer).to receive(:log_info) { |msg| log_messages << msg }

      anonymizer.anonymize_all!

      expect(
        log_messages.any? { |msg| msg.include?("Starting PII anonymization") }
      ).to be true
      expect(
        log_messages.any? { |msg| msg.include?("completed successfully") }
      ).to be true
    end
  end

  describe "progress tracking" do
    let(:progress_callback) { instance_double(Proc) }
    let(:anonymizer) do
      described_class.new(
        config_path: test_config_path,
        dry_run: true,
        progress_callback:
      )
    end

    it "calls progress callback when provided" do
      expect(progress_callback).to receive(:call).with(
        "names",
        anything,
        anything
      ).at_least(:once)

      allow(anonymizer).to receive(:get_table_count).and_return(1)
      anonymizer.anonymize_all!
    end
  end

  describe "integration" do
    let(:anonymizer) do
      described_class.new(config_path: test_config_path, dry_run: true)
    end

    it "processes complete anonymization workflow" do
      allow(anonymizer).to receive(:get_table_count).and_return(5)

      log_messages = []
      allow(anonymizer).to receive(:log_info) { |msg| log_messages << msg }

      anonymizer.anonymize_all!

      expect(
        log_messages.any? do |msg|
          msg.include?("Processing information type: names")
        end
      ).to be true
      expect(
        log_messages.any? { |msg| msg.include?("Total users records: 5") }
      ).to be true
    end

    it "handles parallel processing correctly" do
      allow(anonymizer).to receive(:get_table_count).and_return(25)

      batch_calls = []
      allow(anonymizer).to receive(
        :process_information_batch!
      ) do |_config, offset, size|
        batch_calls << { offset:, size: }
      end

      anonymizer.anonymize_all!

      expect(batch_calls.size).to eq(3) # 25 records / 10 batch_size = 3 batches
      expect(batch_calls.map { |b| b[:offset] }).to contain_exactly(0, 10, 20)
    end
  end

  describe "error handling" do
    let(:anonymizer) do
      described_class.new(config_path: test_config_path, dry_run: true)
    end

    it "handles missing configuration gracefully" do
      expect {
        anonymizer.send(:anonymize_information_type!, "nonexistent")
      }.to raise_error(
        PIIAnonymizer::ConfigurationError,
        /No configuration found/
      )
    end

    it "handles invalid faker methods gracefully" do
      field_config = { "faker_method" => "Invalid::Method.call" }
      value = anonymizer.send(:generate_fake_value, field_config)

      expect(value).to start_with("GENERATION_ERROR_")
    end
  end
end
