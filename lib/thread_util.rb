module ThreadUtil
	def self.threaded_conn(*args)
		Thread.new(*args) do
			begin
				yield
			rescue => e
			ensure
				ActiveRecord::Base.connection.close if ActiveRecord::Base.connection
			end
		end
	end
end