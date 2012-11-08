require 'json'

class Bus < App
	attr_accessor :radius

	def set_defaults
		self.radius = 250
	end

	def departures *args
		address  = args.join(' ')

		response = self.get "https://maps.googleapis.com/maps/api/geocode/json?sensor=false&address=#{address}"
		geometry = JSON.parse(response.body_str)['results'][0]['geometry']['location']

		opts = {
			"Circle"         => [geometry['lat'], geometry['lng'], self.radius].join(','),
			# "StopPointState" => 0,
			# "ReturnList"     => "StopPointName,Bearing,StopPointIndicator,StopPointType"
			# "ReturnList" => "StopPointName,LineName,EstimatedTime,StopID"
		}
		qs = opts.map {|k, v| "#{k}=#{v}"}.join('&')
		response = self.get("#{self.endpoint}?#{qs}")

		now = Time.now
		buses = Bus.fix_broken_json(response)
		buses.shift
		buses = buses.map do |b|
			departure_time = Time.at(b[3].to_i / 1000)
		    interval = (departure_time - now).to_f / 60

			{ code: b[2], stop: b[1], interval: interval }
		end

		buses.sort_by{|b| b[:interval]}[0..20].each do |b|
			puts "#{b[:code]} from #{b[:stop]} in #{b[:interval].to_i == 0 ? '<1 minute' : b[:interval].to_i.to_s + ' minutes'}"
		end
	end

	def endpoint
		"http://countdown.api.tfl.gov.uk/interfaces/ura/instant_V1"
	end

	class << self
		def fix_broken_json response
			JSON.parse("[#{response.body_str.split("\r\n").join(',')}]")
		end
	end
end