module PostsHelper
	private
	# serializer helper
	def post_projs
		post_tb = Post.arel_table
		[
			post_tb[:content],
			arel_sql_epoch(post_tb, :created_at, :timestamp)
		]
	end
end
