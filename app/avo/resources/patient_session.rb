class Avo::Resources::PatientSession < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   query.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :session_id, as: :number
  field :patient_id, as: :number
  field :state, as: :text
  field :patient, as: :belongs_to
  field :session, as: :belongs_to
  field :triage, as: :has_many
  field :vaccination_records, as: :has_many
  field :gillick_competent, as: :boolean
  field :gillick_competence_notes, as: :textarea
  # add fields here
end
