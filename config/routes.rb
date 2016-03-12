Rails.application.routes.draw do
	root to: 'static#index'

	scope format: true, constraints: { format: :json } do

		resources :users, only: [:create]
		controller :users, path: '/user' do
				put '/',                                   action: :update
				patch '/',                                 action: :update_avatar

				post '/login',                             action: :create_session
				put '/logout',                             action: :destroy_session

				put '/follow/:username',                   action: :update_relationship
		end

		resources :posts, only: [:create]
		controller :posts, path: '/post' do
			get '/:inf_id',                              action: :send_post
			post '/share/:from_inf_id',                  action: :share_post
		end

		controller :posts, path: '/posts' do
			get '/:page',                                action: :send_timeline
			get '/following/:page',                      action: :send_follow_timeline
		end

		controller :users, path: '/:username' do
			get '/',                                     action: :user_info
		end
	end

	# load application container by default
	get '*path', to: 'static#index'
end
