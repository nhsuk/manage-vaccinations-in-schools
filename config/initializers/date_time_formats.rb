# frozen_string_literal: true
Date::DATE_FORMATS[:nhsuk_date] = "%-d %B %Y"
Date::DATE_FORMATS[:nhsuk_date_day_of_week] = "%A, %-d %B %Y"
Date::DATE_FORMATS[:nhsuk_date_short_month] = "%-d %b %Y"
Date::DATE_FORMATS[:sunday_1_may] = "%A %-d %B"
Date::DATE_FORMATS[:"1_may"] = "%-d %B"
Date::DATE_FORMATS[:YYYYMMDD] = "%Y%m%d"

Time::DATE_FORMATS[:nhsuk_date] = "%-d %B %Y"
Time::DATE_FORMATS[:nhsuk_date_day_of_week] = "%A, %-d %B %Y"
Time::DATE_FORMATS[:nhsuk_date_short_month] = "%-d %b %Y"

Time::DATE_FORMATS[:time] = "%-l:%M%P"
Time::DATE_FORMATS[:app_date_time] = "%-d %b %Y at %-l:%M%P"
Time::DATE_FORMATS[:app_date_time_long] = "%A %-d %B %Y at %-l:%M%P"
