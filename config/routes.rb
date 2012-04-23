Etm::Application.routes.draw do
  root :to => 'pages#index'

  match 'login'  => 'user_sessions#new',     :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout

  resources :user_sessions

  # Frontend
  resources :converters, :only => [:show]
  resources :users

  scope '/api/v2', :module => 'api' do
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
    resources :areas, :only => [:show, :index]
    resources :inputs, :only => [:index, :show]
    resources :gqueries, :only => [:index]
    # catches all OPTIONS requests
    match '*url', to: 'base#cross_site_sharing', via: :options
  end

  namespace :api do
    namespace :v3 do
      resources :scenarios, :only => [:show, :create, :update] do
        get :templates, :on => :collection
        resources :converters, :only => :show
        resources :inputs, :only => [:index, :show]
      end
      resources :converters, :only => :show
      resources :inputs, :only => [:index, :show]
    end
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
      resources :blueprint_layouts, :except => [:update, :destroy] do
        resources :converter_positions, :only => :create
      end

      resources :gqueries do
        get :result, :on => :member
        collection do
          get :dump
          post :dump
          get :test
          post :test
          get :result
          get :group_descriptions
        end
      end
      match "/gqueries/key/:key" => "gqueries#key", :as => :gquery_key

      resources :converters, :only => [:index, :show]
      resources :gquery_groups, :only => [:index, :show]
      resources :carriers, :only => [:index, :show]
      resource  :area, :as => :area, :only => :show

      resources :query_tables
      resources :query_table_cells, :except => [:show, :index]
      resources :inputs, :except => :show

      resources :scenarios, :only => [:index, :show, :edit, :update, :new] do
        put :fix, :on => :member
      end
      resources :energy_balance_groups

      match '/checks/:action' => 'checks'

      match '/gql' => "gql#index"
      match '/gql/search' => "gql#search", :as => :gql_search
      match '/gql/log' => "gql#log", :as => :gql_log
    end
  end

  namespace :etsource do
    root :to => 'commits#index'

    resources :commits, :only => [:index, :show] do
      get :import, :on => :member
    end
  end

  namespace :input_tool do
    root :to => "wizards#index"
    resources :wizards do
      get :compiled, :on => :member
    end
  end
end
