class Avo::Resources::Session < Avo::BaseResource
  self.title = :name
  self.includes = []
  self.record_selector = false
  # self.search_query = -> do
  #   query.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  def fields
    field :id, as: :id
    # Fields generated from the model
    field :name, as: :text
    field :date, as: :date_time
    field :campaign, as: :belongs_to
    field :location, as: :belongs_to
    field :patients, as: :has_and_belongs_to_many
    # add fields here
    field :send_consent_at, as: :date_time
    field :send_reminders_at, as: :date_time
    field :close_consent_at, as: :date_time
  end
end
