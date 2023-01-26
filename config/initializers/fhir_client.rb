if Settings.features.fhir_server_integration
  FHIR::Model.client = FHIR::Client.new(Settings.fhir_server_url)
end
