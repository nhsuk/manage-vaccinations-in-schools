# frozen_string_literal: true

module CampaignsHelper
  def campaign_academic_year(campaign)
    year_1 = campaign.academic_year.to_s
    year_2 = (campaign.academic_year + 1).to_s
    "#{year_1}/#{year_2[2..3]}"
  end
end
