#!/usr/bin/env bash

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-}/bin:$PATH"

# Weather fetching script for Vibeshell
# Usage: weather.sh [location]
# If no location is provided, uses GeoIP to determine location
# Output: JSON with weather data or error

LOCATION="${1:-}"
MAX_RETRIES=3
RETRY_DELAY=2

if [[ "${LOCATION,,}" == "auto" ]]; then
	LOCATION=""
fi

# Function to make HTTP request with retries
http_get() {
	local url="$1"
	local attempt=1
	local response=""

	while [[ $attempt -le $MAX_RETRIES ]]; do
		response=$(curl -s --max-time 15 --retry 2 --retry-delay 1 "$url" 2>/dev/null)
		if [[ -n "$response" && "$response" != "null" ]]; then
			echo "$response"
			return 0
		fi
		attempt=$((attempt + 1))
		sleep $RETRY_DELAY
	done

	return 1
}

# Function to get coordinates from GeoIP
resolve_geoip() {
	local response
	response=$(http_get "https://ipapi.co/json/")

	if [[ -z "$response" ]]; then
		echo '{"error": "GeoIP request failed"}'
		return 1
	fi

	local lat lon location
	lat=$(echo "$response" | jq -r '.latitude // empty')
	lon=$(echo "$response" | jq -r '.longitude // empty')
	location=$(echo "$response" | jq -r '[.city, .region, .country_name] | map(select(. != null and . != "")) | join(", ")')

	if [[ -z "$lat" || -z "$lon" ]]; then
		echo '{"error": "Could not determine location from GeoIP"}'
		return 1
	fi

	if [[ -z "$location" ]]; then
		location="$lat,$lon"
	fi

	jq -cn --argjson lat "$lat" --argjson lon "$lon" --arg location "$location" \
		'{lat: $lat, lon: $lon, location: $location}'
}

# Function to geocode a city name
resolve_city() {
	local city="$1"
	local encoded_city
	encoded_city=$(echo -n "$city" | jq -sRr @uri)

	local response
	response=$(http_get "https://geocoding-api.open-meteo.com/v1/search?name=${encoded_city}&count=1&language=en&format=json")

	if [[ -z "$response" ]]; then
		echo '{"error": "Geocoding request failed"}'
		return 1
	fi

	local lat lon location
	lat=$(echo "$response" | jq -r '.results[0].latitude // empty')
	lon=$(echo "$response" | jq -r '.results[0].longitude // empty')
	location=$(echo "$response" | jq -r '.results[0] as $r | [$r.name, $r.admin1, $r.country] | map(select(. != null and . != "")) | join(", ")')

	if [[ -z "$lat" || -z "$lon" ]]; then
		echo '{"error": "City not found"}'
		return 1
	fi

	if [[ -z "$location" ]]; then
		location="$city"
	fi

	jq -cn --argjson lat "$lat" --argjson lon "$lon" --arg location "$location" \
		'{lat: $lat, lon: $lon, location: $location}'
}

# Function to fetch weather data
fetch_weather() {
	local lat="$1"
	local lon="$2"
	local location="$3"

	local url="https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,weather_code,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,weather_code&timezone=auto&forecast_days=7"

	local response
	response=$(http_get "$url")

	if [[ -z "$response" ]]; then
		echo '{"error": "Weather API request failed"}'
		return 1
	fi

	# Validate response has required fields
	local has_current has_daily
	has_current=$(echo "$response" | jq -r 'if (.current or .current_weather) then 1 else empty end')
	has_daily=$(echo "$response" | jq -r '.daily // empty')

	if [[ -z "$has_current" || -z "$has_daily" ]]; then
		echo '{"error": "Invalid weather API response"}'
		return 1
	fi

	echo "$response" | jq --arg location "$location" --argjson latitude "$lat" --argjson longitude "$lon" \
		'. + {vibeshell: {location: $location, latitude: $latitude, longitude: $longitude}}'
}

# Main logic
main() {
	local resolution lat lon resolved_location

	if [[ -z "$LOCATION" ]]; then
		# No location provided, use GeoIP
		resolution=$(resolve_geoip || true)
		if [[ "$resolution" == "{"*error* ]]; then
			# It's an error JSON
			echo "$resolution"
			exit 1
		fi
	elif [[ "$LOCATION" =~ ^-?[0-9]+\.?[0-9]*,-?[0-9]+\.?[0-9]*$ ]]; then
		# Location is coordinates (lat,lon)
		lat="${LOCATION%,*}"
		lon="${LOCATION#*,}"
		resolution=$(jq -cn --argjson lat "$lat" --argjson lon "$lon" --arg location "$LOCATION" \
			'{lat: $lat, lon: $lon, location: $location}')
	else
		# Location is a city name, geocode it
		resolution=$(resolve_city "$LOCATION" || true)
		if [[ "$resolution" == "{"*error* ]]; then
			# Try a simpler city-only query if input contains commas
			if [[ "$LOCATION" == *","* ]]; then
				local city_only
				city_only=$(echo "$LOCATION" | awk -F',' '{print $1}' | xargs)
				if [[ -n "$city_only" ]]; then
					resolution=$(resolve_city "$city_only" || true)
				fi
			fi
		fi

		if [[ "$resolution" == "{"*error* ]]; then
			# Fallback to GeoIP if geocoding failed
			resolution=$(resolve_geoip || true)
			if [[ "$resolution" == "{"*error* ]]; then
				echo "$resolution"
				exit 1
			fi
		fi
	fi

	lat=$(echo "$resolution" | jq -r '.lat // empty')
	lon=$(echo "$resolution" | jq -r '.lon // empty')
	resolved_location=$(echo "$resolution" | jq -r '.location // empty')

	if [[ -z "$lat" || -z "$lon" ]]; then
		echo '{"error": "Could not resolve weather coordinates"}'
		exit 1
	fi
	if [[ -z "$resolved_location" ]]; then
		resolved_location="$lat,$lon"
	fi

	# Fetch and output weather
	fetch_weather "$lat" "$lon" "$resolved_location"
}

main
