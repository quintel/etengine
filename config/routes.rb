# config/routes.rb

Rails.application.routes.draw do
  # Mounts external Identity Engine
  mount Identity::Engine => '/auth'

  # Main landing page
  root to: 'pages#index'

  # --------------------------------------------------------------------------
  # API V3
  # --------------------------------------------------------------------------
  namespace :api do
    namespace :v3 do
      resource :user, only: %i[update destroy]
      resources :areas, only: %i[index show]
      resources :gqueries, only: :index

      resources :scenarios, only: %i[index show create update destroy] do
        member do
          get :batch
          get :application_demands,     to: 'export#application_demands'
          get :production_parameters,   to: 'export#production_parameters'
          get :energy_flow,            to: 'export#energy_flow'
          get :molecule_flow,          to: 'export#molecule_flow'
          get :costs_parameters,       to: 'export#costs_parameters'
          get :sankey,                 to: 'export#sankey'
          get :storage_parameters,     to: 'export#storage_parameters'
          get :merit
          put :dashboard
          post :interpolate
          post :uncouple
          post :couple
        end

        collection do
          post :merge
          get  :templates
          get  'versions', to: 'scenario_version_tags#index'
        end

        #TODO: is this still necessary?
        # Redirection of old converter routes to new nodes route
        get 'converters',      to: redirect('/api/v3/scenarios/%{scenario_id}/nodes')
        get 'converters/:id',  to: redirect('/api/v3/scenarios/%{scenario_id}/nodes/%{id}')

        resources :nodes, only: :show do
          collection do
            get :topology
            post :stats
          end
        end

        resources :inputs, only: %i[index show]

        resource :version, only: %i[create show update], controller: 'scenario_version_tags'

        # TODO: Do we still need these removed_features routes?
        # Removed feature: flexibility_order
        get   :flexibility_order, to: 'removed_features#flexibility_order'
        put   :flexibility_order, to: 'removed_features#flexibility_order'
        patch :flexibility_order, to: 'removed_features#flexibility_order'


        resource :heat_network_order,                     only: %i[show update],
          controller: :user_sortables, sortable_type: :heat_network

        resource :forecast_storage_order,                 only: %i[show update],
          controller: :user_sortables, sortable_type: :forecast_storage

        resource :hydrogen_supply_order,                  only: %i[show update],
          controller: :user_sortables, sortable_type: :hydrogen_supply

        resource :hydrogen_demand_order,                  only: %i[show update],
          controller: :user_sortables, sortable_type: :hydrogen_demand

        resource :households_space_heating_producer_order, only: %i[show update],
          controller: :user_sortables, sortable_type: :space_heating

        resources :custom_curves, only: %i[index show update destroy],
                  constraints: { id: %r{[a-z\d_\-/]+} }

        resource :esdl_file, only: %i[show update]

        resources :users, only: %i[index create update destroy], controller: 'scenario_users' do
          collection do
            post :create
            put :update
            delete :destroy
          end
        end

        resources :curves, only: [] do
          collection do
            get :buildings_heat,         to: 'curves#buildings_heat_curves',   as: :buildings_heat_download
            get :merit_order,            to: 'curves#merit_order',            as: :merit_order_download
            get :electricity_price,      to: 'curves#electricity_price',      as: :electricity_price_download
            get :heat_network,           to: 'curves#heat_network',           as: :heat_network_download
            get :agriculture_heat,       to: 'curves#agriculture_heat',       as: :agriculture_heat_download
            get :household_heat,         to: 'curves#household_heat_curves',  as: :household_heat_download
            get :hydrogen,               to: 'curves#hydrogen',               as: :hydrogen_download
            get :network_gas,            to: 'curves#network_gas',            as: :network_gas_download
            get :residual_load,          to: 'curves#residual_load',          as: :residual_load_download
            get :hydrogen_integral_cost, to: 'curves#hydrogen_integral_cost', as: :hydrogen_integral_cost_download
          end
        end
      end

      resources :saved_scenarios, except: %i[new]
      resources :collections

      # Redirecting old transition paths routes to collections
      resources :transition_paths, controller: :collections

      resources :inputs, only: %i[index show] do
        get :list, on: :collection
      end
    end
  end

  # --------------------------------------------------------------------------
  # MECHANICAL TURK
  # --------------------------------------------------------------------------
  namespace :mechanical_turk do
    root to: 'turks#index'
    resource :factory, only: %i[new create show]
    resources :turks,  only: %i[index show]
  end

  # --------------------------------------------------------------------------
  # INSPECT
  # --------------------------------------------------------------------------
  namespace :inspect do
    get '/'          => 'pages#start_inspect'
    get '/redirect'  => 'base#redirect', as: 'redirect'

    put '/staff_application/:id' => 'staff_applications#update', as: :staff_application

    get 'search.js' => 'search#index', as: :search_autocomplete

    scope '/:api_scenario_id' do
      root to: 'pages#index'
      post '/clear_cache' => 'pages#clear_cache', as: 'clear_cache'

      resources :layouts, except: %i[new index create destroy] do
        member { get :yaml }
      end

      get 'layout', to: redirect('api/v3/scenarios/%{api_scenario_id}/layout/energy')

      resources :gqueries, only: %i[index show] do
        member   { get :result }
        collection do
          get :test
          post :test
          get :result
        end
      end

      scope '/graphs/:graph_name' do
        resources :nodes, only: %i[index show]
      end

      resources :carriers, only: %i[index show]
      resource :area, only: :show

      resources :query_tables

      resources :query_table_cells, except: %i[show index]

      resources :inputs, only: %i[index show]

      resources :scenarios, only: %i[index show edit update new create] do
        put :fix, on: :member
      end

      # Checks
      get '/checks/share_groups'      => 'checks#share_groups'
      get '/checks/gquery_results'    => 'checks#gquery_results'
      get '/checks/loops'            => 'checks#loops'
      get '/checks/expected_demand'  => 'checks#expected_demand'
      get '/checks/index'            => 'checks#index'

      # Debug
      get '/debug/merit_order'   => 'debug#merit_order'
      get '/debug/calculation'   => 'debug#calculation'
      get '/debug/gquery'        => 'debug#gquery', as: :debug_gql

      # GQL
      get '/gql'          => 'gql#index'
      get '/gql/search'   => 'gql#search',   as: :gql_search
      get '/gql/log'      => 'gql#log',      as: :gql_log
      get '/gql/warnings' => 'gql#warnings', as: :gql_warnings

      get '/merit' => 'merit#index'
      get '/merit/download',        to: redirect('api/v3/scenarios/%{api_scenario_id}/merit/loads.csv')
      get '/merit/download_prices', to: redirect('api/v3/scenarios/%{api_scenario_id}/merit/price.csv')

      # Old routes for converters
      get 'converters',        to: redirect('/inspect/%{api_scenario_id}/nodes')
      get 'converters/:id',    to: redirect('/inspect/%{api_scenario_id}/nodes/%{id}')

      get 'search' => 'search#index', as: :search
    end
  end

  # Misc Redirections
  get '/data',               to: redirect('/inspect', status: 302)
  get '/my_etm/:page',         to: 'redirect#set_cookie_and_redirect', as: :my_etm

  get '/data/*rest',
    to: redirect(status: 302) { |params| "/inspect/#{params[:rest]}" }

  # --------------------------------------------------------------------------
  # ETSOURCE
  # --------------------------------------------------------------------------
  namespace :etsource do
    root to: 'commits#index'
    resources :commits, only: :index do
      get :import, on: :member
    end
  end
end
