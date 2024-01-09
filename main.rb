require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/calendar_v3'
require 'fileutils'
require 'date'
require 'active_support/all'
require 'set'


CLIENT_SECRETS_PATH = './client_secrets.json'
CREDENTIALS_PATH = './token.yaml'

def initialize_calendar_service
  scope = Google::Apis::CalendarV3::AUTH_CALENDAR
  client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store)
  credentials = authorizer.get_credentials('user_id')

  service = Google::Apis::CalendarV3::CalendarService.new
  service.client_options.application_name = 'Google Calendar API Ruby'
  service.authorization = credentials if credentials

  service
end

def authorize_and_load_client
  service = initialize_calendar_service

  if service.authorization.nil?
    credentials = authorize
    save_credentials(credentials)
    service.authorization = credentials
  end

  service
end

def authorize
  client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
  scope = Google::Apis::CalendarV3::AUTH_CALENDAR
  user_id = 'default'
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)

  authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store)

  credentials = authorizer.get_credentials(user_id)

  if credentials.nil?
    url = authorizer.get_authorization_url(base_url: 'urn:ietf:wg:oauth:2.0:oob')
    puts "Open the following URL in your browser to authorize:\n#{url}"
    puts 'Enter the authorization code:'
    code = gets.chomp
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: 'urn:ietf:wg:oauth:2.0:oob'
    )
  end

  credentials
end

def save_credentials(credentials)
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))
  File.open(CREDENTIALS_PATH, 'w') do |file|
    file.write(credentials.to_yaml)
  end
end

def list_events(service)
  calendar_id = 'primary'
  start_time = Time.now.beginning_of_month.iso8601
  end_time = Time.now.end_of_month.iso8601

  response = service.list_events(calendar_id,
                                 max_results: 1000,
                                 single_events: true,
                                 order_by: 'startTime',
                                 time_min: start_time,
                                 time_max: end_time,
                                 fields: 'items(summary,attendees)') # Request only summary and attendees fields

  puts 'Events in the current month:'
  puts 'No upcoming events found' if response.items.empty?

  events_summary = Hash.new { |hash, key| hash[key] = { count: 0, attendees: Set.new } }


  response.items.each do |event|
    summary = event.summary
    attendees = event.attendees || []

    puts "- #{summary}"

    # Summarize by event name and list participants
    events_summary[summary][:count] += 1
    events_summary[summary][:attendees] |= attendees.map { |attendee| attendee.email.to_s } unless attendees.empty?
  end

  month_name = Time.now.strftime("%B") # Get the full month name
  puts "\nSummary of events in #{month_name}:"
  events_summary.each do |event_name, info|
    puts "- #{event_name}: #{info[:count]} times"
    puts "  Participants: #{info[:attendees].join(', ')}"
  end
end



begin
  service = authorize_and_load_client
  list_events(service)
rescue Google::Apis::ClientError => e
  puts "Error: #{e}"
end


# Authorization code
# Please copy this code, switch to your application and paste it there
# 4/1AfJohXkdi6UscQf8r8fxGl47dPYZ_UGOSCpTXTF1jL5Oyj1bAccJVbI3k0U