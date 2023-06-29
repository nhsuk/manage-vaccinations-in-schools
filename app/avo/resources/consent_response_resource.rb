class ConsentResponseResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :patient_id, as: :number
  field :campaign_id, as: :number
  field :childs_name, as: :textarea
  field :childs_common_name, as: :textarea
  field :childs_dob, as: :date
  field :address_line_1, as: :textarea
  field :address_line_2, as: :textarea
  field :address_town, as: :textarea
  field :address_postcode, as: :textarea
  field :parent_name, as: :textarea
  field :parent_relationship,
        as: :select,
        enum: ::ConsentResponse.parent_relationships
  field :parent_relationship_other, as: :textarea
  field :parent_email, as: :textarea
  field :parent_phone, as: :textarea
  field :parent_contact_method, as: :number
  field :parent_contact_method_other, as: :textarea
  field :consent, as: :select, enum: ::ConsentResponse.consents
  field :reason_for_refusal,
        as: :select,
        enum: ::ConsentResponse.reason_for_refusals
  field :reason_for_refusal_other, as: :textarea
  field :gp_response, as: :select, enum: ::ConsentResponse.gp_responses
  field :gp_name, as: :textarea
  field :route, as: :select, enum: ::ConsentResponse.routes
  field :health_questions, as: :text
  field :patient, as: :belongs_to
  field :campaign, as: :belongs_to
  # add fields here
end
