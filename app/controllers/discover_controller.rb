class DiscoverController < ApplicationController
	SEARCH_ITEMS_PER_PAGE = 10

	def search_all
		query = ActiveRecord::Base.sanitize((params[:q] || '').gsub(/\s/, ':* & '))
		page = params[:p] || 1

		@users_tb = User.arel_table
		@urels_tb = UserRelationship.arel_table

		@users_search_query_ast = @users_tb
		.project(
			@users_tb[:name],
			@users_tb[:username],
			avatar_url_attr(:thumb, :avatarThumb),
			avatar_url_attr(:medium, :avatarMedium),
			Arel.sql('"users"."properties" -> \'info\'').as('"userInfo"'),

			@users_tb[:total_read_influence].as('"totalRdInf"'),
			@users_tb[:total_share_influence].as('"totalShInf"'),
			@users_tb[:total_shares].as('"totalShares"'),
			@users_tb[:total_posts].as('"totalPosts"'),

			Arel.sql(<<-SQL.squish
				CASE WHEN #{current_user.try(:id) || 'NULL'} IS NULL THEN
					NULL
				WHEN "user_relationships"."id" IS NOT NULL THEN
					TRUE
				ELSE
					FALSE
				END
			SQL
			).as('"followStatus"'),

			Arel.sql(<<-SQL.squish
				SIMILARITY("users"."username", #{query}) + 
				SIMILARITY("users"."name", #{query})
			SQL
			).as('"relv_score"')
		)
		.join(@urels_tb, Arel::Nodes::OuterJoin)
		.on(
			@users_tb[:id].eq(@urels_tb[:follows_id])
			.and(@urels_tb[:follower_id].eq(current_user.try(:id)))
		)
		.where(
			Arel.sql(<<-SQL.squish
				"users"."username" % #{query}
				OR
				"users"."name" % #{query}
			SQL
			)
		)
		.order(
			Arel.sql('"relv_score"').desc
		)

		@users_search_query_ast = paginate(@users_search_query_ast, page, SEARCH_ITEMS_PER_PAGE)

		@users_search_cte = Arel::Table.new(:users_cte)
		@users_search_cte_as = Arel::Nodes::As.new(@users_search_cte, @users_search_query_ast)

		# agg user search
		@users_agg_query = Arel.sql(<<-SQL.squish
			(SELECT JSON_AGG("users_agg") AS "users_agg"
			FROM (#{
				@users_search_cte.project(
					@users_search_cte[:name],
					@users_search_cte[:username],
					@users_search_cte[:avatarThumb],
					@users_search_cte[:avatarMedium],
					@users_search_cte[:userInfo],
					@users_search_cte[:totalRdInf],
					@users_search_cte[:totalShInf],
					@users_search_cte[:totalShares],
					@users_search_cte[:totalPosts],
					@users_search_cte[:followStatus]
				).to_sql
			}) AS "users_agg")
		SQL
		)

		@users_agg_cte = Arel::Table.new(:users_agg_cte)
		@users_agg_cte_as = Arel::Nodes::As.new(@users_agg_cte, @users_agg_query)

		@query_ast = @users_agg_cte
		.project(
			@users_agg_cte[:users_agg].as('users')
		)
		.with(
			@users_search_cte_as,
			@users_agg_cte_as
		)


		render jsonize(
			json_agg_exec(@query_ast, prefix: 'SELECT SET_LIMIT(0.05);').first
		)
	end

	private


end
