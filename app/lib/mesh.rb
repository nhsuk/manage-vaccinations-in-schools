# frozen_string_literal: true

module MESH
  SCHEMA = "NHSMESH"

  def self.connection
    authorisation = generate_authorisation
    Faraday.new(
      "#{base_url}/messageexchange/#{mailbox}/",
      ssl: {
        verify: true,
        client_cert: OpenSSL::X509::Certificate.new(Settings.mesh.certificate),
        client_key:
          OpenSSL::PKey::RSA.new(
            Settings.mesh.private_key,
            Settings.mesh.private_key_passphrase
          ),
        ca_file: Rails.root.join("config", "mesh_ca_bundle.pem").to_s
      },
      headers: {
        "Accept" => "application/vnd.mesh.v2+json",
        "Authorization" => "#{SCHEMA} #{authorisation}"
      }
    )
  end

  def self.send_file(to:, data:)
    headers = {
      "Content-Type" => "text/csv",
      "Content-Encoding" => "gzip",
      "mex-to" => to,
      "mex-workflowid" => "dps export"
    }

    connection.post("outbox", Zlib.gzip(data), headers)
  end

  def self.generate_authorisation
    nonce = SecureRandom.uuid
    nonce_count = 1
    timestamp = Time.zone.now.utc.strftime("%Y%m%d%H%M")
    hash_payload = [mailbox, nonce, nonce_count, password, timestamp].join(":")
    hash = OpenSSL::HMAC.hexdigest("SHA256", shared_key, hash_payload)

    [mailbox, nonce, nonce_count, timestamp, hash].join(":")
  end

  def self.mailbox
    Settings.mesh.mailbox
  end

  def self.password
    Settings.mesh.password
  end

  def self.shared_key
    Settings.mesh.shared_key
  end

  def self.base_url
    Settings.mesh.base_url
  end
end
