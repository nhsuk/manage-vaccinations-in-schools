# frozen_string_literal: true

# Here we replace the standard Rails date and time formats with slightly
# different versions based on the guidance in the NHS service manual.
# See https://railsdatetimeformats.com/ for the default values.

# Dates - https://service-manual.nhs.uk/content/numbers-measurements-dates-time#dates

Date::DATE_FORMATS[:short] = "%-d %B" # 1 January
Date::DATE_FORMATS[:short_day_of_week] = "%A %-d %B" # Monday 1 January

Date::DATE_FORMATS[:long] = "%-d %B %Y" # 5 January 2023
Date::DATE_FORMATS[:long_day_of_week] = "%A %-d %B %Y" # Wednesday 5 January 2023

Date::DATE_FORMATS[:uk_short] = "%d/%m/%Y" # 01/01/2020
Date::DATE_FORMATS[:dps] = "%Y%m%d" # 20230105

# Time - https://service-manual.nhs.uk/content/numbers-measurements-dates-time#time

Time::DATE_FORMATS[:time] = "%-l:%M%P" # 3:45pm

Time::DATE_FORMATS[:long] = "%-d %B %Y at %-l:%M%P" # 5 January 2023 at 3:45pm
