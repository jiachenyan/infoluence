Rails.application.routes.draw do
	root to: 'static#index'

	scope format: true, constraints: { format: :json } do

		resources :user, only: [:create]
		controller :users, path: '/user' do
				put '/',                                   action: :update
				patch '/',                                 action: :update_avatar

				post '/login',                             action: :create_session
				put '/logout',                             action: :destroy_session
		end

		resources :post, only: [:create]
	end

	# load application container by default
	get '*path', to: 'static#index'
end
