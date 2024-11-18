# frozen_string_literal: true

ActiveRecord::SessionStore::Session.table_name = "active_record_sessions"
ActiveRecord::SessionStore::Session.serializer = :json

Rails.application.config.session_store :active_record_store,
                                       key: "_session_id",
                                       secure: Rails.env.production?,
                                       expire_after: 12.hours
