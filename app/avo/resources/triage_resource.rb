class TriageResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :campaign_id, as: :number
  field :patient_id, as: :number
  field :status, as: :select, enum: ::Triage.statuses
  field :notes, as: :textarea
  field :campaign, as: :belongs_to
  field :patient, as: :belongs_to
  # add fields here
end
