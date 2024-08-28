# frozen_string_literal: true

module NHS::PDS::Patient
  class << self
    def find(nhs_number)
      NHS::PDS.connection.get("Patient/#{nhs_number}")
    end
  end
end
