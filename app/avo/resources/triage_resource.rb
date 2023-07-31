class TriageResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :patient_session_id, as: :number
  field :status, as: :select, enum: ::Triage.statuses
  field :notes, as: :textarea
  field :campaign, as: :belongs_to
  field :patient_session, as: :belongs_to
  # add fields here
end
