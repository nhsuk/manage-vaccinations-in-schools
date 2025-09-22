# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_notification_programmes
#
#  id                      :bigint           not null, primary key
#  consent_notification_id :bigint           not null
#  programme_id            :bigint           not null
#
# Indexes
#
#  idx_on_consent_notification_id_bde310472f               (consent_notification_id)
#  idx_on_programme_id_consent_notification_id_e185bde5f5  (programme_id,consent_notification_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (consent_notification_id => consent_notifications.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id) ON DELETE => cascade
#
class ConsentNotificationProgramme < ApplicationRecord
  belongs_to :consent_notification
  belongs_to :programme
end
