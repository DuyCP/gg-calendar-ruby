require 'google_calendar'

# Replace these variables with your credentials and the email address
CLIENT_ID = "559995491604-qeft742bn25l1bbcmf26rhohvpupp1cb.apps.googleusercontent.com"
CLIENT_SECRET = "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"
CALENDAR_ID = 'primary' # Use 'primary' for the primary calendar

# Create a new Google Calendar client
cal = Google::Calendar.new(
  client_id:     CLIENT_ID,
  client_secret: CLIENT_SECRET,
  calendar:      CALENDAR_ID,
  redirect_url:  "urn:ietf:wg:oauth:2.0:oob"
)

# Generate OAuth2 authorization URL
auth_url = cal.authorize_url

# Print the authorization URL and prompt the user to visit it and get the authorization code
puts "Please visit the following URL to authorize the application:"
puts auth_url
puts "Enter the authorization code:"
authorization_code = gets.chomp

# Fetch access token using the authorization code
access_token = cal.login_with_auth_code(authorization_code)

# Get all events for the specified email address
events = cal.events

# Print the events
if events.empty?
    puts "No events found."
else
    puts "Events for calendar #{CALENDAR_ID}:"
    events.each do |event|
        puts "- #{event.title} at #{event.start_time}"
    end
end