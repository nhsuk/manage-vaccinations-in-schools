# frozen_string_literal: true

# == Schema Information
#
# Table name: notify_log_entry_programmes
#
#  disease_types       :enum             not null, is an Array
#  programme_type      :enum             not null, primary key
#  notify_log_entry_id :bigint           not null, primary key
#
# Indexes
#
#  index_notify_log_entry_programmes_on_notify_log_entry_id  (notify_log_entry_id)
#
# Foreign Keys
#
#  fk_rails_...  (notify_log_entry_id => notify_log_entries.id)
#
class NotifyLogEntry::Programme < ApplicationRecord
  belongs_to :notify_log_entry, inverse_of: :notify_log_entry_programmes
end
