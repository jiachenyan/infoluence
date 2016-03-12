module PostsHelper
	private

	# serializer helper
	def post_projs
		post_tb = Post.arel_table
		[
			post_tb[:id].as('"postId"'),
			post_tb[:content],
			post_tb[:total_reads].as('"totalReads"'),
			post_tb[:total_shares].as('"totalShares"'),
			arel_sql_epoch(post_tb, :created_at, :timestamp)
		]
	end
end
