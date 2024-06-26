# frozen_string_literal: true

Date::DATE_FORMATS[:nhsuk_date] = "%-d %B %Y" # 5 January 2023
Date::DATE_FORMATS[:nhsuk_date_day_of_week] = "%A, %-d %B %Y" # Wednesday, 5 January 2023
Date::DATE_FORMATS[:nhsuk_date_short_month] = "%-d %b %Y" # 5 Jan 2023
Date::DATE_FORMATS[:sunday_1_may] = "%A %-d %B" # Sunday 1 May
Date::DATE_FORMATS[:"1_may"] = "%-d %B" # 1 May
Date::DATE_FORMATS[:YYYYMMDD] = "%Y%m%d" # 20230105

Time::DATE_FORMATS[:nhsuk_date] = "%-d %B %Y" # 5 January 2023
Time::DATE_FORMATS[:nhsuk_date_day_of_week] = "%A, %-d %B %Y" # Wednesday, 5 January 2023
Time::DATE_FORMATS[:nhsuk_date_short_month] = "%-d %b %Y" # 5 Jan 2023

Time::DATE_FORMATS[:time] = "%-l:%M%P" # 3:45pm
Time::DATE_FORMATS[:app_date_time] = "%-d %b %Y at %-l:%M%P" # 5 Jan 2023 at 3:45pm
Time::DATE_FORMATS[:app_date_time_long] = "%A %-d %B %Y at %-l:%M%P" # Wednesday 5 January 2023 at 3:45pm
