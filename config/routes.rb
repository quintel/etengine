Etm::Application.routes.draw do
  root :to => 'pages#index'

  match 'login'  => 'user_sessions#new',     :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout

  resources :user_sessions

  # Frontend
  resources :users, :except => :show
  match '/graph' => 'data/blueprint_layouts#show', :defaults => {:api_scenario_id => 'latest', :id => 1}

  namespace :api do

    namespace :v2 do
      resources :scenarios, :only => [:index, :show, :create, :update] do
        get :load, :on => :member
        collection do
          get :homepage
        end
      end
      resources :api_scenarios do
        member do
          get :user_values
          get :input_data
        end
      end
      resources :areas, :only => [:index, :show]
      resources :inputs, :only => :index
      resources :gqueries, :only => [:index]
      # catches all OPTIONS requests
      match '*url', to: 'base#cross_site_sharing', via: :options
    end

    namespace :v3 do
      resources :areas, :only => [:index, :show]
      resources :scenarios, :only => [:show, :create, :update] do
        member do
          get :sandbox
        end
        get :templates, :on => :collection
        resources :converters, :only => :show do
          get :topology, :on => :collection
        end
        resources :inputs, :only => [:index, :show]
      end
      resources :converters, :only => :show do
        get :topology, :on => :collection
      end
      resources :inputs, :only => [:index, :show] do
        get :list, :on => :collection
      end
    end
  end

  namespace :mechanical_turk do
    root :to => 'turks#index'
    resource :factory, :only => [:new, :create, :show]
    resources :turks, :only => [:index, :show]
  end

  namespace :data do
    root :to => "pages#index", :api_scenario_id => 'latest'

    match '/redirect'    => "base#redirect", :as => 'redirect'
    match '/restart'     => 'pages#restart', :as => 'restart'
    match '/clear_cache' => 'pages#clear_cache', :as => 'clear_cache'

    scope '/:api_scenario_id' do
      # Hanlde paths from previous routes.
      scope "/nl" do
        match "*path" => "pages#url_changed"
      end

      root :to => "pages#index"

      # The Graphviz
      resource :layout, :except => [:new, :index, :create, :destroy]

      resources :gqueries, :only => [:index, :show] do
        get :result, :on => :member
        collection do
          get :test
          post :test
          get :result
        end
      end

      resources :converters, :only => [:index, :show]
      resources :carriers, :only => [:index, :show]
      resource  :area, :as => :area, :only => :show

      resources :query_tables
      resources :query_table_cells, :except => [:show, :index]
      resources :inputs, :only => [:index, :show]

      resources :scenarios, :only => [:index, :show, :edit, :update, :new] do
        put :fix, :on => :member
      end
      resources :energy_balance_groups, only: [:index]

      match '/share_groups' => 'share_groups#index'

      match '/checks/:action' => 'checks'

      match '/debug/merit_order' => 'debug#merit_order'
      match '/debug/calculation' => 'debug#calculation'
      match '/debug/gquery' => 'debug#gquery', :as => :debug_gql

      match '/gql' => "gql#index"
      match '/gql/search' => "gql#search", :as => :gql_search
      match '/gql/log' => "gql#log", :as => :gql_log
      match '/gql/warnings' => "gql#warnings", :as => :gql_warnings

      match 'search' => 'search#index', :as => :search
    end
  end

  namespace :etsource do
    root :to => 'commits#index'

    resources :commits, :only => [:index, :show] do
      get :import, :on => :member
    end
  end
end
