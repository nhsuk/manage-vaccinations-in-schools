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
  field :site, as: :select, enum: ::VaccinationRecord.sites
  field :recorded_at, as: :date
  # add fields here
end
