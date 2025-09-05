# frozen_string_literal: true

Mime::Type.register "application/manifest+json", :webmanifest

Mime::Type.register "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    :xlsx

Mime::Type.register "text/csv", :csv
Mime::Type.register "application/json", :json
