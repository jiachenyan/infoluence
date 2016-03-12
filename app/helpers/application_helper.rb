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
		col_name = col_name.to_s

		if as_name
			as_name = as_name.to_s
		elsif camelize_col?(col_name)
			as_name = col_name.camelize(:lower)
		else
			as_name = col_name
		end		

		Arel.sql( <<-SQL.squish
			EXTRACT(EPOCH FROM "#{arel_tb.name}"."#{col_name}")::INT
		SQL
		).as("\"#{as_name}\"")
	end

	def camelize_col?(col_name)
		# convert if all lowercase and has underscore
		(!(col_name =~ /[A-Z]/) and (col_name =~ /\_/))
	end
end
