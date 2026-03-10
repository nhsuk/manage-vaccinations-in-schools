# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccination_report_exports
#
#  id             :uuid             not null, primary key
#  academic_year  :integer          not null
#  date_from      :date
#  date_to        :date
#  expired_at     :datetime
#  file_format    :string           not null
#  programme_type :string           not null
#  status         :string           default("pending"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  team_id        :bigint           not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_vaccination_report_exports_on_created_at  (created_at)
#  index_vaccination_report_exports_on_status      (status)
#  index_vaccination_report_exports_on_team_id     (team_id)
#  index_vaccination_report_exports_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (user_id => users.id)
#
class VaccinationReportExport < ApplicationRecord
  FILE_FORMATS = %w[mavis systm_one careplus].freeze

  belongs_to :team
  belongs_to :user

  has_one_attached :file

  enum :status, { pending: "pending", ready: "ready", failed: "failed", expired: "expired" }

  validates :programme_type, presence: true, inclusion: { in: Programme::TYPES }
  validates :academic_year, presence: true
  validates :file_format, presence: true, inclusion: { in: :valid_file_formats }
  validate :careplus_available_for_team, if: -> { file_format == "careplus" }

  def expired?
    return true if status == "expired"
    return false if expired_at.blank?

    expired_at <= Time.current
  end

  def file_formats
    common = %w[mavis systm_one]
    team.careplus_enabled? ? common + ["careplus"] : common
  end

  def programme
    Programme.find(programme_type) if programme_type
  end

  def csv_filename
    return nil unless programme

    from_str = date_from&.to_fs(:long) || "earliest"
    to_str = date_to&.to_fs(:long) || "latest"

    "#{programme.name} - #{file_format} - #{from_str} - #{to_str}.csv"
  end

  def set_expired_at!
    retention_hours = Settings.vaccination_report_export.retention_hours
    update!(expired_at: created_at + retention_hours.hours) if expired_at.blank?
  end

  private

  def valid_file_formats
    file_formats
  end

  def careplus_available_for_team
    return if team.careplus_enabled?

    errors.add(:file_format, "is not available for this team")
  end
end
