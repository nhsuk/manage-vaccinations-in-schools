Rails.application.routes.draw do
  devise_for :users,
             module: :users,
             path_names: {
               sign_in: "sign-in",
               sign_out: "sign-out"
             }
  get "sign-in", to: redirect("/users/sign_in")

  root to: redirect("/start")

  constraints -> { !Rails.env.production? } do
    mount Avo::Engine, at: Avo.configuration.root_path
    mount GoodJob::Engine => "/good-job"
    mount Flipper::UI.app => "/flipper"
  end

  get "/start", to: "pages#start"
  get "/dashboard", to: "dashboard#index"

  get "/ping" => proc { [200, {}, ["PONG"]] }

  if Rails.env.development? || Rails.env.test?
    get "/reset", to: "dev#reset"
    get "/random_consent_form", to: "dev#random_consent_form"
  end

  get "/csrf", to: "csrf#new"

  resources :sessions, only: %i[index show] do
    get "consents", to: "consents#index", on: :member
    get "triage", to: "triage#index", on: :member
    get "vaccinations", to: "vaccinations#index", on: :member

    constraints -> { Flipper.enabled?(:make_session_in_progress_button) } do
      put "make-in-progress", to: "sessions#make_in_progress", on: :member
    end

    namespace :parent_interface, path: "/" do
      resources :consent_forms, path: :consents, only: [:create] do
        get "start", on: :collection
        get "cannot-consent"
        get "confirm"
        put "record"

        resources :edit, only: %i[show update], controller: "consent_forms/edit"
      end
    end

    resources :patients do
      resource :consents, only: %i[show]

      resource :triage, only: %i[create show update]

      resource :vaccinations, only: %i[new create show update] do
        get "history", on: :member

        resource "batch",
                 only: %i[edit update],
                 controller: "vaccinations/batches"
        resource "delivery_site",
                 only: %i[edit update],
                 controller: "vaccinations/delivery_site"
        get "edit/reason", action: "edit_reason", on: :member
        get "confirm", on: :member
        put "record", on: :member

        post "handle-consent", on: :member

        get "show-template", on: :collection
        get "record-template", on: :collection
      end

      constraints -> { Flipper.enabled?(:new_consents) } do
        post ":route/consents",
             to: "manage_consents#create",
             as: :manage_consents
        resources :manage_consents,
                  only: %i[show update],
                  path: ":route/consents/:consent_id/"
      end

      constraints -> { !Flipper.enabled?(:new_consents) } do
        resource :nurse_consents, path: ":route/consent" do
          get "assessing-gillick", to: "nurse_consents#assessing_gillick"

          get "edit/gillick", to: "nurse_consents#edit_gillick"
          put "update/gillick", to: "nurse_consents#update_gillick"

          get "edit/who", to: "nurse_consents#edit_who"
          get "edit/agree", to: "nurse_consents#edit_consent"
          get "edit/reason", to: "nurse_consents#edit_reason"
          get "edit/questions", to: "nurse_consents#edit_questions"
          get "edit/confirm", to: "nurse_consents#edit_confirm"

          put "record"
        end
      end
    end

    get "setup-offline", to: "offline_passwords#new", on: :member
    post "setup-offline", to: "offline_passwords#create", on: :member
  end

  scope via: :all do
    get "/404", to: "errors#not_found"
    get "/422", to: "errors#unprocessable_entity"
    get "/429", to: "errors#too_many_requests"
    get "/500", to: "errors#internal_server_error"
  end
end
