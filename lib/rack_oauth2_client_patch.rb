# frozen_string_literal: true

module RackOAuth2ClientPatch
  # absolute_uri_for strips out the port if it's the default, e.g.
  # https://host.com:443 becomes https://host.com. CIS2, however, uses URLs with
  # the port and requires that we match it exactly.
  #
  # Generally, if a passed-in URL has a scheme (http(s)) then we can assume
  # it's already an absolute uri.
  def absolute_uri_for(*args)
    return args.first if args.first.starts_with?(/^https?:/)

    super(*args)
  end
end
