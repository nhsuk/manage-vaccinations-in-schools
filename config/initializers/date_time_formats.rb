# frozen_string_literal: true
Date::DATE_FORMATS[:nhsuk_date] = "%-d %B %Y"
Date::DATE_FORMATS[:nhsuk_date_day_of_week] = "%A %-d %B %Y"
Date::DATE_FORMATS[:nhsuk_date_short_month] = "%-d %b %Y"

Time::DATE_FORMATS[:nhsuk_date] = "%-d %B %Y"
Time::DATE_FORMATS[:nhsuk_date_day_of_week] = "%A %-d %B %Y"
Time::DATE_FORMATS[:nhsuk_date_short_month] = "%-d %b %Y"

Time::DATE_FORMATS[:long_ordinal_uk] = "%-d %B %Y at %l:%M%P"
Time::DATE_FORMATS[:time] = "%-l:%M%P"
Time::DATE_FORMATS[:app_date_time] = "%-d %b %Y at %-l:%M%P"
Time::DATE_FORMATS[:app_date_time_long] = "%A %-d %B %Y at %-l:%M%P"
