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
end
