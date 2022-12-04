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
		Subdomain.current.tracking_enabled && request.cookies['cookies_accepted'] == 'true'
	end
end
