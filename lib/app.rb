require 'curb'

class App
	def initialize
		if self.respond_to? :set_defaults
			self.set_defaults
		end
	end

	def get url
		request = Curl::Easy.new(url) do |curl|
		    curl.timeout = 10
		end

		begin
		    request.perform
		rescue Curl::Err::TimeoutError => e
		    $stderr.puts "Request timed out :("
		    exit 1
		rescue StandardError => e
		    $stderr.puts e.message
		    exit 1
		end

		request.status == '200 OK' ? request : false
	end
end