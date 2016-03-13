module ApplicationHelper
	def jsonize(object)
		object = Oj.dump(object) unless object.is_a?(String)
		{ json: object }
	end

	def json_success(obj)
		jsonize({ success: obj })
	end
		
	def json_error(*msgs)
		msg_strings = Array.new

		msgs.each do |msg|
			if msg.is_a?(Array)
				msg_strings += msg
			elsif msg.is_a?(String)
				msg_strings << msg
			elsif msg.is_a?(ActiveRecord::Base)
				msg_strings += msg.errors.full_messages
			else
				raise ArgumentError, "Cannot add #{msg.class.name} to errors"
			end
		end
		
		jsonize({ errors: msg_strings })
	end


	# serializer helpers

	def paginate(query_ast, page, items_per_page)
		page = page.to_i unless page.is_a?(Fixnum)
		offset = 0
		offset = (page-1)*items_per_page if page > 1
		query_ast.take(items_per_page).skip(offset)
	end

	def json_agg_exec(query_ast)
		data = ActiveRecord::Base.connection.execute <<-SQL.squish
			SELECT
			JSON_AGG("data") AS "data"
			FROM(#{query_ast.to_sql}) AS "data"
		SQL

		data = data.first['data']
		if data.nil?
			Array.new
		else
			Oj.load(data)
		end
	end

	def arel_sql_epoch(arel_tb, col_name, as_name=nil)
		arel_sql = Arel.sql <<-SQL.squish
			CAST(EXTRACT(EPOCH FROM "#{arel_tb.name}"."#{col_name}") AS INT)
		SQL

		arel_sql = arel_sql.as("\"#{as_name}\"") unless as_name.nil?
		arel_sql
	end

	def json_build_object(*values)
		Arel::Nodes::NamedFunction.new('JSON_BUILD_OBJECT', values)
	end

	def json_build_array(*values)
		Arel::Nodes::NamedFunction.new('JSON_BUILD_ARRAY', values)
	end

	def json_agg(*values)
		Arel::Nodes::NamedFunction.new('JSON_AGG', values)
	end
end
