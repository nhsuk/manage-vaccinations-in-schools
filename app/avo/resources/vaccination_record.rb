class Avo::Resources::VaccinationRecord < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   query.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  def fields
    field :id, as: :id
    # Fields generated from the model
    field :patient_session, as: :belongs_to
    field :administered, as: :boolean
    field :delivery_site, as: :select, enum: ::VaccinationRecord.delivery_sites
    field :delivery_method,
          as: :select,
          enum: ::VaccinationRecord.delivery_methods
    field :recorded_at, as: :date
    # add fields here
  end
end
