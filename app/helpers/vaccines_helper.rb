module VaccinesHelper
  def vaccine_heading(vaccine)
    sprintf("%s (%s)", vaccine.brand, t(vaccine.type, scope: "vaccines"))
  end
end
