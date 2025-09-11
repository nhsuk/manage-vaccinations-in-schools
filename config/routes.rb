# frozen_string_literal: true

require "sidekiq/web"
require "sidekiq-scheduler/web"
require "sidekiq/throttled/web"

Rails.application.routes.draw do
  # Redirect www subdomain to root in production envs
  unless Rails.env.local?
    match "(*any)",
          to: redirect(subdomain: ""),
          via: :all,
          constraints: {
            subdomain: "www"
          }
  end

  get "/logout", to: "users/logout#show"

  if Settings.cis2.enabled
    devise_for :users,
               module: :users,
               controllers: {
                 omniauth_callbacks: "users/omniauth_callbacks"
               }
    devise_scope :user do
      post "/users/auth/cis2/backchannel-logout",
           to: "users/omniauth_callbacks#cis2_logout"
      delete "/logout", to: "users/omniauth_callbacks#logout"
    end
  else
    devise_for :users,
               module: :users,
               path_names: {
                 sign_in: "sign-in",
                 sign_out: "sign-out"
               }
    devise_scope :user do
      delete "/logout", to: "users/sessions#destroy"
    end
  end

  root to: redirect("/start")

  mount GoodJob::Engine => "/good-job"

  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(
      Rails.application.credentials.support_username,
      username
    ) &&
      ActiveSupport::SecurityUtils.secure_compare(
        Rails.application.credentials.support_password,
        password
      )
  end
  mount Sidekiq::Web => "/sidekiq"

  get "/start", to: "pages#start"
  get "/dashboard", to: "dashboard#index"
  get "/accessibility-statement", to: "content#accessibility_statement"

  get "/manifest/:name.json", to: "manifest#show", as: :manifest

  get "/up", to: "rails/health#show", as: :rails_health_check

  flipper_app =
    Flipper::UI.app do |builder|
      builder.use Rack::Auth::Basic do |username, password|
        ActiveSupport::SecurityUtils.secure_compare(
          Rails.application.credentials.support_username,
          username
        ) &&
          ActiveSupport::SecurityUtils.secure_compare(
            Rails.application.credentials.support_password,
            password
          )
      end
    end
  mount flipper_app, at: "/flipper"

  unless Rails.env.production?
    get "/random-consent-form(/:slug)", to: "dev/random_consent_form#call"
  end

  get "/csrf", to: "csrf#new"

  namespace :parent_interface, path: "/" do
    resources :consent_forms, path: "/consents", only: %i[create] do
      collection do
        get ":session_slug/:programme_types/start", action: "start", as: :start
        get ":session_slug/:programme_types/deadline-passed",
            action: "deadline_passed",
            as: :deadline_passed
      end

      member do
        get "cannot-consent-responsibility"
        get "confirm"
        put "record"
      end

      resources :edit, only: %i[show update], controller: "consent_forms/edit"
    end
  end

  namespace :api do
    unless Rails.env.production?
      namespace :testing do
        resources :locations, only: :index
        resources :teams, only: :destroy, param: :workgroup
        post "/onboard", to: "onboard#create"
      end
      namespace :reporting do
        post "authorize", to: "one_time_tokens#authorize"
        get "totals", controller: :totals, action: :index
        resources :vaccination_events, path: "vaccination-events", only: :index
      end
    end
  end

  resources :class_imports, path: "class-imports", except: %i[index destroy]

  resources :cohort_imports, path: "cohort-imports", except: %i[index destroy]

  resources :consent_forms, path: "consent-forms", only: %i[index show] do
    member do
      get "search"

      get "match/:patient_id", action: :edit_match, as: :match
      post "match/:patient_id", action: :update_match

      get "archive", action: :edit_archive
      post "archive", action: :update_archive

      get "patient", action: :new_patient
      post "patient", action: :create_patient
    end
  end

  resource :draft_import, only: %i[show update], path: "draft-import/:id"
  resource :draft_consent, only: %i[show update], path: "draft-consent/:id"
  resource :draft_vaccination_record,
           only: %i[show update],
           path: "draft-vaccination-record/:id"

  resources :immunisation_imports,
            path: "immunisation-imports",
            except: %i[index destroy]

  resources :imports, only: %i[index create]

  namespace :imports do
    resources :issues, path: "issues", only: %i[index] do
      get ":type", action: :show, on: :member, as: ""
      patch ":type", action: :update, on: :member
    end

    resources :notices, only: :index
  end

  resources :notifications, only: :create

  resources :patients, only: %i[index show edit] do
    post "", action: :index, on: :collection

    resource :archive,
             path: "archive",
             only: %i[new create],
             controller: "patients/archive"

    resources :parent_relationships,
              path: "parents",
              only: %i[edit update destroy] do
      get "destroy", action: :confirm_destroy, on: :member, as: "destroy"
    end

    member do
      get "log"
      post "invite-to-clinic"

      get "edit/nhs-number",
          controller: "patients/edit",
          action: "edit_nhs_number"
      put "edit/nhs-number",
          controller: "patients/edit",
          action: "update_nhs_number"
      put "edit/nhs-number-merge",
          controller: "patients/edit",
          action: "update_nhs_number_merge"
    end
  end

  resources :programmes, only: :index, param: :type do
    get "consent-form", on: :member, action: :consent_form

    scope module: :programmes do
      resource :overview,
               path: ":academic_year",
               only: :show,
               controller: :overview
      resources :patients, path: ":academic_year/patients", only: :index do
        get "import", on: :collection
      end
      resources :reports, path: ":academic_year/reports", only: :create
      resources :sessions, path: ":academic_year/sessions", only: :index
    end
  end

  resources :school_moves, path: "school-moves", only: %i[index show update]
  resources :school_move_exports,
            path: "school-moves/exports",
            controller: "school_moves/exports",
            only: %i[create show update] do
    get "download", on: :member
  end

  resources :sessions, only: %i[index show], param: :slug do
    resource :patients, only: :show, controller: "sessions/patients"
    resource :consent, only: :show, controller: "sessions/consent"
    resource :triage, only: :show, controller: "sessions/triage"
    resource :patient_specific_directions,
             path: "patient-specific-directions",
             only: %i[show new create],
             controller: "sessions/patient_specific_directions"
    resource :register, only: :show, controller: "sessions/register" do
      post ":patient_id/:status", as: :create, action: :create
    end
    resource :record, only: :show, controller: "sessions/record" do
      get "batch/:programme_type/:vaccine_method",
          action: :edit_batch,
          as: :batch
      post "batch/:programme_type/:vaccine_method", action: :update_batch
    end

    resource :edit, only: :show, controller: "sessions/edit" do
      get "programmes"
      put "programmes", action: :update_programmes

      get "send-consent-requests-at"
      put "send-consent-requests-at", action: :update_send_consent_requests_at

      get "send-invitations-at"
      put "send-invitations-at", action: :update_send_invitations_at

      get "weeks-before-consent-reminders"
      put "weeks-before-consent-reminders",
          action: :update_weeks_before_consent_reminders

      get "register-attendance"
      put "register-attendance", action: :update_register_attendance

      get "delegation"
      put "delegation", action: :update_delegation
    end

    resource :invite_to_clinic,
             path: "invite-to-clinic",
             only: %i[edit update],
             controller: "sessions/invite_to_clinic"

    resource :manage_consent_reminders,
             path: "manage-consent-reminders",
             only: %i[show create],
             controller: "sessions/manage_consent_reminders"

    member do
      get "import"

      constraints -> { Flipper.enabled?(:dev_tools) } do
        put "make-in-progress", to: "sessions#make_in_progress"
      end

      constraints -> { Flipper.enabled?(:offline_working) } do
        get "setup-offline", to: "offline_passwords#new"
        post "setup-offline", to: "offline_passwords#create"
      end
    end

    resource :dates, controller: "session_dates", only: %i[show update]

    resources :patient_sessions,
              path: "patients",
              as: :patient,
              only: [],
              module: :patient_sessions do
      resource :activity, only: %i[show create]
      resource :attendance, only: %i[edit update]

      resources :programmes, path: "", param: :type, only: :show do
        get "record-already-vaccinated"

        resources :consents, only: %i[index create show] do
          post "send-request", on: :collection, action: :send_request

          member do
            get "withdraw", action: :edit_withdraw
            post "withdraw", action: :update_withdraw

            get "invalidate", action: :edit_invalidate
            post "invalidate", action: :update_invalidate
          end
        end

        resource :gillick_assessment, path: "gillick", only: %i[edit update]
        resource :triages, only: %i[new create]
        resource :vaccinations, only: %i[create]
      end
    end
  end

  resource :team, only: %i[show]

  resources :vaccination_records,
            path: "vaccination-records",
            only: %i[show update destroy] do
    get "destroy", action: :confirm_destroy, on: :member, as: "destroy"
  end

  resource :vaccination_report,
           only: %i[show update],
           path: "vaccination-report/:id" do
    get "download", on: :member
  end

  resources :vaccines, only: %i[index show] do
    resources :batches, only: %i[create edit new update] do
      member do
        get "archive", action: "edit_archive"
        post "archive", action: "update_archive"

        post "make-default", as: :make_default
      end
    end
  end

  namespace :users do
    get "organisation-not-found", controller: :errors
    get "workgroup-not-found", controller: :errors
    get "role-not-found", controller: :errors

    resource :teams, only: %i[new create]
  end

  scope via: :all do
    get "/404", to: "errors#not_found"
    get "/422", to: "errors#unprocessable_entity"
    get "/429", to: "errors#too_many_requests"
    get "/500", to: "errors#internal_server_error"
  end

  get "/oidc/jwks", to: "jwks#jwks"
end
