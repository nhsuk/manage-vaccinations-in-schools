# frozen_string_literal: true

Rails.application.routes.draw do
  # Redirect www subdomain to root in production envs
  unless Rails.env.development? || Rails.env.test?
    match "(*any)",
          to: redirect(subdomain: ""),
          via: :all,
          constraints: {
            subdomain: "www"
          }
  end

  devise_for :users,
             module: :users,
             path_names: {
               sign_in: "sign-in",
               sign_out: "sign-out"
             },
             controllers: {
               omniauth_callbacks: "users/omniauth_callbacks"
             }
  get "sign-in", to: redirect("/users/sign_in")
  devise_scope :user do
    post "auth/cis2_logout", to: "users/omniauth_callbacks#cis2_logout"
  end

  root to: redirect("/start")

  mount GoodJob::Engine => "/good-job"

  get "/start", to: "pages#start"
  get "/dashboard", to: "dashboard#index"
  get "/accessibility-statement", to: "content#accessibility_statement"
  get "/privacy-policy", to: "content#privacy_policy"

  get "/ping" => proc { [200, {}, ["PONG"]] }

  flipper_app =
    Flipper::UI.app do |builder|
      builder.use Rack::Auth::Basic do |username, password|
        ActiveSupport::SecurityUtils.secure_compare(
          Settings.support_username,
          username
        ) &&
          ActiveSupport::SecurityUtils.secure_compare(
            Settings.support_password,
            password
          )
      end
    end
  mount flipper_app, at: "/flipper"

  if Rails.env.development? || Rails.env.test?
    get "/reset", to: "dev#reset"
    get "/random_consent_form", to: "dev#random_consent_form"
  end

  constraints -> { Flipper.enabled?(:dev_tools) } do
    get "/reset/:team_ods_code", to: "dev#reset_team", as: :reset_team
  end

  get "/csrf", to: "csrf#new"

  namespace :parent_interface, path: "/" do
    resources :consent_forms, path: "/consents", only: %i[create] do
      collection do
        get ":session_id/:programme_id/start", action: "start", as: :start
        get ":session_id/:programme_id/deadline-passed",
            action: "deadline_passed",
            as: :deadline_passed
      end

      get "cannot-consent-responsibility"
      get "cannot-consent-school"
      get "confirm"
      put "record"

      resources :edit, only: %i[show update], controller: "consent_forms/edit"
    end
  end

  resources :programmes, only: %i[index show] do
    get "sessions", on: :member

    resources :cohort_imports, path: "cohort-imports", except: %i[index destroy]

    resources :cohorts, only: %i[index show]

    resources :immunisation_imports,
              path: "immunisation-imports",
              except: %i[index destroy] do
      resources :duplicates,
                only: %i[show update],
                controller: "immunisation_imports/duplicates"
    end

    resources :import_issues, path: "import-issues", only: %i[index show update]

    resources :imports, only: %i[index new create]

    resources :vaccination_records,
              path: "vaccination-records",
              only: %i[index show] do
      post "export-dps", on: :collection
      constraints -> { Flipper.enabled?(:dev_tools) } do
        post "reset-dps-export", on: :collection
      end

      get "edit/date-and-time",
          controller: "vaccination_records/edit",
          action: "edit_date_and_time"
      put "edit/date-and-time",
          controller: "vaccination_records/edit",
          action: "update_date_and_time"
    end
  end

  resources :sessions, only: %i[edit index show] do
    collection do
      get "completed"
      get "scheduled"
      get "unscheduled"
    end

    resources :class_imports, path: "class-imports", except: %i[index destroy]

    resource :dates, controller: "session_dates", only: %i[show update]

    constraints -> { Flipper.enabled?(:dev_tools) } do
      put "make-in-progress", to: "sessions#make_in_progress", on: :member
    end

    constraints -> { Flipper.enabled? :offline_working } do
      get "setup-offline", to: "offline_passwords#new", on: :member
      post "setup-offline", to: "offline_passwords#create", on: :member
    end
  end

  scope "/sessions/:session_id/:section", as: "session" do
    constraints section: "consents" do
      defaults section: "consents" do
        get "/",
            as: "consents",
            to:
              redirect(
                "/sessions/%{session_id}/consents/#{TAB_PATHS[:consents].keys.first}"
              )

        get "unmatched-responses",
            to: "consent_forms#unmatched_responses",
            as: :consents_unmatched_responses

        get ":tab",
            controller: "consents",
            action: :index,
            as: :consents_tab,
            tab: TAB_PATHS[:consents].keys.join("|")
      end
    end

    constraints section: "triage" do
      defaults section: "triage" do
        get "/",
            as: "triage",
            to:
              redirect(
                "/sessions/%{session_id}/triage/#{TAB_PATHS[:triage].keys.first}"
              )

        get ":tab",
            controller: "triages",
            action: :index,
            as: :triage_tab,
            tab: TAB_PATHS[:triage].keys.join("|")
      end
    end

    constraints section: "vaccinations" do
      defaults section: "vaccinations" do
        get "/",
            as: "vaccinations",
            to:
              redirect(
                "/sessions/%{session_id}/vaccinations/#{TAB_PATHS[:vaccinations].keys.first}"
              )

        get "batch", to: "vaccinations#batch"
        patch "batch", to: "vaccinations#update_batch"

        get ":tab",
            controller: "vaccinations",
            action: :index,
            as: :vaccinations_tab,
            tab: TAB_PATHS[:vaccinations].keys.join("|")
      end
    end

    scope ":tab" do
      resources :patients, only: %i[show] do
        get "log"

        post "consents", to: "manage_consents#create", as: :manage_consents
        resources :manage_consents,
                  only: %i[show update],
                  path: "consents/:consent_id/" do
          get "details", on: :collection, to: "consents#show"
        end

        resource :gillick_assessment, only: %i[new create]

        resource :gillick_assessment,
                 path: "gillick-assessment/:id",
                 only: %i[show update]

        resource :triages, only: %i[new create]

        resource :vaccinations, only: %i[create] do
          resource "edit",
                   only: %i[show update],
                   controller: "vaccinations/edit",
                   path: "edit/:id"
        end
      end
    end

    # These are just used to create helpers with better names that allow passing
    # in section and/or tab as a parameter. e.g. session_section_path(@session,
    # section: @section) which looks cleaner than session_triage_path(@session,
    # section: @section)
    get "/", to: "errors#not_found", as: "section"
    get "/:tab", to: "errors#not_found", as: "section_tab"
  end

  resource :team, only: %i[show]

  resources :vaccines, only: %i[index show] do
    resources :batches, only: %i[create edit new update] do
      post "make-default", on: :member, as: :make_default
    end
  end

  resources :consent_forms, path: "consent-forms", only: [:show] do
    get "match/:patient_session_id",
        on: :member,
        to: "consent_forms#review_match",
        as: :review_match
    post "match/:patient_session_id",
         on: :member,
         to: "consent_forms#match",
         as: :match
  end

  namespace :users do
    get "team-not-found", controller: :errors
    get "role-not-found", controller: :errors
  end

  scope via: :all do
    get "/404", to: "errors#not_found"
    get "/422", to: "errors#unprocessable_entity"
    get "/429", to: "errors#too_many_requests"
    get "/500", to: "errors#internal_server_error"
  end
end
