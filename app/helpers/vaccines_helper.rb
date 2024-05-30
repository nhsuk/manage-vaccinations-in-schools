module VaccinesHelper
  def vaccine_heading(vaccine)
    "%s (%s)" % [vaccine.brand, t(vaccine.type.downcase, scope: "vaccines")]
  end
end
