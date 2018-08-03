Rails.application.routes.draw do
  devise_scope :admin do
    authenticated :admin do
      root to: redirect("admin/facilities"), as: :admin_root
    end

    unauthenticated :admin do
      root to: "devise/sessions#new"
    end
  end

  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do
    namespace :v1 do
      get 'ping', to: 'pings#show'
      post 'login', to: 'logins#login_user'

      scope :users do
        post 'register', to: 'users#register'
        get 'find', to: 'users#find'
      end

      scope '/patients' do
        get 'sync', to: 'patients#sync_to_user'
        post 'sync', to: 'patients#sync_from_user'
      end

      scope '/blood_pressures' do
        get 'sync', to: 'blood_pressures#sync_to_user'
        post 'sync', to: 'blood_pressures#sync_from_user'
      end

      scope '/prescription_drugs' do
        get 'sync', to: 'prescription_drugs#sync_to_user'
        post 'sync', to: 'prescription_drugs#sync_from_user'
      end

      scope '/facilities' do
        get 'sync', to: 'facilities#sync_to_user'
      end

      scope '/protocols' do
        get 'sync', to: 'protocols#sync_to_user'
      end
    end
  end

  devise_for :admins

  namespace :admin do
    resources :facilities do
      resources :users do
        put 'reset_otp', to: 'users#reset_otp'
        put 'disable_access', to: 'users#disable_access'
        put 'enable_access', to: 'users#enable_access'
      end
    end

    resources :protocols do
      resources :protocol_drugs
    end
  end

  if FeatureToggle.enabled?('PURGE_ENDPOINT_FOR_QA')
    namespace :qa do
      delete 'purge', to: 'purges#purge_patient_data'
    end
  end
end
