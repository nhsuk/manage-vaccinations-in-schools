class VaccinationRecordResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :patient_session, as: :belongs_to
  field :administered, as: :boolean
  field :delivery_site, as: :select, enum: ::VaccinationRecord.delivery_sites
  field :delivery_method,
        as: :select,
        enum: ::VaccinationRecord.delivery_methods
  field :recorded_at, as: :date
  field :user, as: :belongs_to
  field :notes, as: :text
  # add fields here
end
