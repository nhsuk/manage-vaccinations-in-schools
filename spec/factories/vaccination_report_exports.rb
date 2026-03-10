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
FactoryBot.define do
  factory :vaccination_report_export do
    team { create(:team, :with_one_nurse, programmes: [Programme.flu]) }
    user { team.users.first }
    programme_type { "flu" }
    academic_year { 2024 }
    file_format { "mavis" }
    status { "pending" }
  end
end
