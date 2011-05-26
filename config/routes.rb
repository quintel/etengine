Etm::Application.routes.draw do  
  root :to => 'user_sessions#new'

  match 'login'  => 'user_sessions#new', :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout

  resources :user_sessions

  scope '/api/v1', :module => 'api',  do
    resources :api_scenarios
  end

  scope '/api/v2', :module => 'api',  do
    resources :scenarios, :only => [:index, :show, :create, :update] do
      get :load, :on => :member
      collection do
        get :homepage
      end
    end    
    resources :api_scenarios do
      member do 
        get :user_values
      end
    end
    resources :areas, :only => [:index, :show]
  end

  namespace :construction do
    root :to => "blueprint_models#index", :as => 'start'

    resources :blueprint_models
    resources :blueprints
    resources :datasets
    resources :graphs

    scope '/:blueprint_model_id' do
      match '/' => "converters#index"
      resources :converters
      resources :slots
      resources :links
    end
  end
  
  namespace :admin do
    resources :graphs, :only => [:index, :show, :update] do
      collection do
        post :import
      end
    end
    resources :historic_series
    resources :query_tables
    resources :query_table_cells, :except => [:show, :index]
    
    root :to => "pages#index"
  end

  namespace :data do
    root :to => "data#start", :as => 'start'
    match '/redirect' => "data#redirect", :as => 'redirect'
    

    scope '/:blueprint_id/:region_code' do
      match '/' => "converters#index"

      # Todo: this temporary redirect can be removed after 2011-04-24
      match '/graph', :to => redirect("/data/%{blueprint_id}/%{region_code}/blueprint_layouts")
      resources :blueprint_layouts do
        resources :converter_positions
      end
      resources :gql_test_cases

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

      resources :converters do
        resource :converter_data
      end
      resources :converter_data

      resources :carriers do 
        resource :carrier_data
      end
      resources :carrier_data

      resources :areas do
        resources :carrier_data
      end
    end
  end

  match '/:controller(/:action(/:id))'
end
