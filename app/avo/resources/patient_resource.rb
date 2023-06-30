class PatientResource < Avo::BaseResource
  self.title = :full_name
  self.includes = []
  self.record_selector = false
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :first_name, as: :text
  field :last_name, as: :text
  field :preferred_name, as: :text
  field :dob, as: :date
  field :nhs_number, as: :number
  field :sex, as: :select, enum: ::Patient.sexes
  field :screening, as: :select, enum: ::Patient.screenings
  field :consent, as: :select, enum: ::Patient.consents
  field :seen, as: :select, enum: ::Patient.seens
  field :sessions, as: :has_and_belongs_to_many
  field :location, as: :belongs_to
  # add fields here
end
