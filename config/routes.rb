Etm::Application.routes.draw do  
  root :to => 'user_sessions#new'

  match 'login'  => 'user_sessions#new', :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout

  resources :user_sessions

  scope '/api/v1', :module => 'api',  do
    resources :api_scenarios
  end

  scope '/api/v2', :module => 'api',  do
    resources :api_scenarios
    resources :scenarios, :only => [:index, :show]
  end

  namespace :construction do
    match '/' => "blueprint_models#index", :as => 'start'

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

  namespace :data do
    match '/' => "data#start", :as => 'start'
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
      resources :converter_datas

      resources :carriers do 
        resource :carrier_data
      end
      resources :carrier_datas

      resources :areas do
        resources :carrier_datas
      end

      resources :descriptions
    end
  end

  namespace :admin do
    resources :areas,
              :carriers,
              :expert_predictions, 
              :input_elements, # remove?
              :carrier_datas,
              :historic_series, 
              :year_values, 
              :descriptions, 
              :translations, # remove?
              :blackbox_scenarios, 
              :converters, 
              :query_tables, 
              :query_table_cells, 
              :blueprint_converters, 
              :groups, 
              :converter_positions

    resources :blackboxes do
      get :rspec, :on => :member
    end
    resources :graphs do
      collection do
        post :import
      end
      resources :converters
      resources :converter_datas
      collection do
        post :import
      end
    end
    resources :gqueries do
      get :result, :on => :member
      collection do
        get :dump
        post :dump
        get :test
        post :test
        get :result
      end
    end
    resources :blueprints do
      get :graph, :on => :member
      resources :blueprint_converters
      resources :groups
    end
  end

  match '/:controller(/:action(/:id))'
end
