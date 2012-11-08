require 'date'
require 'uri'
require 'cgi'

class MainLine < App
	attr_accessor :num_results

	def set_defaults
		self.num_results = 5
	end

	def departures station, num_results = nil
		url = "http://ojp.nationalrail.co.uk/service/ldb/liveTrainsJson?departing=true&liveTrainsFrom=#{URI::encode(station)}&liveTrainsTo="
		num_results = (num_results || self.num_results).to_i
		if num_results > 50
			$stderr.puts "Sorry, the maximum results to show is 50"
			exit 1
		end

		request = Curl::Easy.new(url) do |curl|
		    curl.timeout = 10
		end

		begin
		    request.perform
		    departures = JSON.parse(request.body_str)
		rescue Curl::Err::TimeoutError => e
		    $stderr.puts "Request timed out :("
		    exit 1
		rescue StandardError => e
		    $stderr.puts e.message
		    exit 1
		end

		if departures['trains'].size == 0
		    puts "No departures listed for station \"#{station}\" :("
		end

		now = Time.now
		i = 0
		messages = []

		departures['trains'].each do |t|
		    hour, minute = *t[1].split(':')
		    departure_time = Time.new(now.year, now.month, now.day, hour, minute)
		    interval = (departure_time - now).to_f / 60

		    if(interval > 0 && i < num_results)
		        i += 1
		        messages << CGI.unescapeHTML("#{t[1]} to #{t[2]} in #{(interval.to_i == 0 ? '<1 minute' : interval.to_i.to_s + ' minutes')}")
		    end
		end

		inner_div = "-" * (messages.sort_by {|m| m.length * -1 }.first.length + 4)
		outer_div = inner_div.gsub("-", "=")

		puts outer_div, " Departures from \"#{station}\"", inner_div
		messages.each {|m| puts "  " + m }
		puts outer_div
	end
end