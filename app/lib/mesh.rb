# frozen_string_literal: true

module MESH
  SCHEMA = "NHSMESH"

  def self.send_file(to:, data:)
    authorisation = generate_authorisation

    headers = {
      "Accept" => "application/vnd.mesh.v2+json",
      "Authorization" => "#{SCHEMA} #{authorisation}",
      "Content-Type" => "text/csv",
      "Content-Encoding" => "gzip",
      "mex-to" => to,
      "mex-workflowid" => "dps export"
    }

    conn =
      Faraday.new("#{base_url}/messageexchange/#{mailbox}/outbox") do |faraday|
        faraday.ssl[:verify] = false if Rails.env.development?
      end

    conn.post do |req|
      req.body = Zlib.gzip(data)
      req.headers = headers
    end
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
