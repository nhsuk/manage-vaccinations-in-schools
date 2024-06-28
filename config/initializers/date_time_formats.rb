# frozen_string_literal: true

Date::DATE_FORMATS[:short] = "%-d %B" # 1 January
Date::DATE_FORMATS[:short_day_of_week] = "%A %-d %B" # Monday 1 January

Date::DATE_FORMATS[:nhsuk_date] = "%-d %B %Y" # 5 January 2023
Date::DATE_FORMATS[:nhsuk_date_day_of_week] = "%A, %-d %B %Y" # Wednesday, 5 January 2023

Time::DATE_FORMATS[:nhsuk_date] = "%-d %B %Y" # 5 January 2023
Time::DATE_FORMATS[:nhsuk_date_day_of_week] = "%A, %-d %B %Y" # Wednesday, 5 January 2023

Time::DATE_FORMATS[:time] = "%-l:%M%P" # 3:45pm
Time::DATE_FORMATS[
  :nhsuk_date_time
] = "#{Time::DATE_FORMATS[:nhsuk_date]} at #{Time::DATE_FORMATS[:time]}"
