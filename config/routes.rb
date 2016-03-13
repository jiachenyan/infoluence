Rails.application.routes.draw do
	module RtCst
		def self.int
			/[1-9]\d*/
		end
	end

	root to: 'static#index'

	scope format: true, constraints: { format: :json } do

		resources :users, only: [:create]
		controller :users, path: '/user', constraints: { page: RtCst.int } do
				put '/',                                   action: :update
				patch '/',                                 action: :update_avatar

				post '/login',                             action: :create_session
				put '/logout',                             action: :destroy_session

				put '/follow/:username',                   action: :update_relationship
		end

		resources :posts, only: [:create]
		controller :posts, path: '/post', constraints: { inf_id: RtCst.int, from_inf_id: RtCst.int } do
			get '/:inf_id',                              action: :send_post
			post '/share/:from_inf_id',                  action: :share_post
		end

		controller :posts, path: '/posts', constraints: { page: RtCst.int } do
			get '/:page',                                action: :send_timeline
			get '/following/:page',                      action: :send_follow_timeline
			get '/user/:username/:page',                      action: :send_user_timeline
		end
		
		controller :links, path: '/link' do
			post '/',                                    action: :save_link
		end

		controller :discover, path: '/discover' do
			# ?q=query&p=page
			get '/',                                     action: :search_all
		end

		controller :users, path: '/:username' do
			get '/',                                     action: :user_info
			get '/following/:page',                      action: :send_followings
		end
	end

	# load application container by default
	get '*path', to: 'static#index'
end
