require 'google/apis/calendar_v3'
require 'googleauth'
require 'json'

# service_account_id = "duyserviceaccountcalendar"
# service_account_mail = "duyserviceaccountcalendar@gg-calendar-ruby.iam.gserviceaccount.com"

# Replace these variables with your service account credentials and the email address
SERVICE_ACCOUNT_EMAIL = 'duyserviceaccountcalendar@gg-calendar-ruby.iam.gserviceaccount.com'
SERVICE_ACCOUNT_FILE = './gg-calendar-ruby-service-account.json'
# CALENDAR_ID = 'primary' # Use 'primary' for the primary calendar
CALENDAR_ID = 'duy@coderpush.com' # Use 'primary' for the primary calendar

# Initialize the Google Calendar API client
calendar = Google::Apis::CalendarV3::CalendarService.new
calendar.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
  json_key_io: File.open(SERVICE_ACCOUNT_FILE),
  scope: Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY
)

# Get all events for the specified calendar
begin
    # Attempt to fetch events from the Google Calendar
    events = calendar.list_events(CALENDAR_ID)

    # Print the events from 2023 and beyond
    if events.items.empty?
        puts "No events found."
    else
        puts "Events for calendar #{CALENDAR_ID} from 2023 onwards:"
        events.items.each do |event|
        # Check if the event's start date is from 2023 or later
        if event.start && event.start.date_time && event.start.date_time >= Date.new(2023, 1, 1)
            puts "- #{event.summary} at #{event.start.date_time}"
        end
        end
    end
    rescue Google::Apis::AuthorizationError => e
    # Handle authorization errors
    puts "Authorization failed: #{e.message}"
end