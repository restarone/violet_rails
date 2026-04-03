module AhoyControllerPatch
	def set_ahoy_cookies
		if Ahoy.cookies && tracking_enabled?
			ahoy.set_visitor_cookie
			ahoy.set_visit_cookie
		else
			# delete cookies if exist
			ahoy.reset
		end
	end

	def tracking_enabled?
		locations = Geocoder.search(request.ip)
		location = locations.first
		track_by_default_country_codes = ['CA', 'US']
		
		if Subdomain.current.tracking_enabled
			if request.cookies['cookies_accepted'] == 'true'
				return true
			else
				if track_by_default_country_codes.include?(location&.country_code&.upcase) 
					cookies[:cookies_accepted] = {
						value: params[:cookies].presence,
						httponly: true,
						expires: 1.year
					}
					return true
				else
					return false
				end
			end
		else
			return false
		end
	end
end
