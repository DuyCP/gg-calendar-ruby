require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/calendar_v3'
require 'fileutils'
require 'date'
require 'active_support/all'
require 'set'
require 'mail'
require 'set'




def merge_sets(*sets)
  merged_array = []
  sets.each do |set|
    merged_array.concat(set.to_a)
  end
  merged_array
end

# Set up email delivery method

CLIENT_SECRETS_PATH = './client_secrets.json'
CREDENTIALS_PATH = './token.yaml'

$from_email = 'txd22081999@gmail.com'
$from_email_password = 'kxtu mipe owot gmxb'
$to_email = 'duy@coderpush.com'

options = { :address              => "smtp.gmail.com",
            :port                 => 587,
            :domain               => 'localhost', # Replace with your domain
            :user_name            => $from_email, # Replace with your Gmail address
            :password             => $from_email_password, # Replace with your Gmail password
            :authentication       => 'plain',
            :enable_starttls_auto => true }

Mail.defaults do
  delivery_method :smtp, options
end

# Send the email
def send_email(subject, body)
  mail = Mail.new do
    from     $from_email
    to       $to_email
    subject   'Hello from gg-calendar-ruby'
    body     body
  end
  mail.deliver
  puts "Mail sent"
end



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

def format_email_body(paragraph)
  # Split the paragraph into lines
  lines = paragraph.split("\n")

  # Add two newline characters between each line
  formatted_body = lines.join("\n\n")

  # Return the formatted body text
  return formatted_body
end

def handle_events(service)
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
  event_str = 'Events in the current month:'
  no_event_str = 'No upcoming events found'
  puts event_str
  puts no_event_str if response.items.empty?

  puts "- response"
  puts response

  events_summary = Hash.new { |hash, key| hash[key] = [] }
  puts "- events_summary"
  puts events_summary

  # response.items.each do |event|
  #   summary = event.summary
  #   attendees = event.attendees || []

  #   puts "- #{summary}"

  #   # Summarize by event name and list participants
  #   events_summary[summary][:count] += 1
  #   events_summary[summary][:attendees] |= attendees.map { |attendee| attendee.email.to_s } unless attendees.empty?
  # end

  response.items.each do |event|
    summary = event.summary
    attendees = event.attendees || []
  
    puts "- #{summary}"
  
    # Add each event summary as an object to the array under the summary key
    events_summary[summary] << { count: 1, attendees: attendees.map { |attendee| attendee.email.to_s } }
  end
  

  puts " - AFTER: events_summary"
  puts events_summary

  puts "🚀 ~ events_summary: #{events_summary}"
  # filtered_events_summary = events_summary.select { |event_name, info| event_name.include?("1-1") }
  # puts filtered_events_summary

  subscribed_list = []
  unsubscribed_list = []

  month_name = Time.now.strftime("%B") # Get the full month name
  puts "\nSummary of events in #{month_name}:"

  output_str = format_events_summary(events_summary)
  puts "- output_str"
  puts output_str
  puts "----- output_str"
  puts format_email_body(output_str)
  subject = "Summary of 1-1 meetings"
  body = output_str
  send_email(subject, body)

  end


  sample_events_summary = {
    "Mystorage - Daily meeting" => [
      {
        :count => 10,
        :attendees => Set.new(["thien.kieu@coderpush.com", "ruby@coderpush.com", "duy@coderpush.com"])
      }
    ],
    "Dux-soup - Daily Sync" => [{
      :count => 21,
      :attendees => Set.new(["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"])
    }],
    "🎙 Open Discussion: E-sports Tournament 2024" => [{
      :count => 1,
      :attendees => Set.new(["hieu.pham@coderpush.com", "nhat@coderpush.com", "cong@coderpush.com", "du@coderpush.com", "vu@coderpush.com", "coral@coderpush.com", "vi@coderpush.com", "dieuhuyen@coderpush.com", "bsu@coderpush.com", "nhatanh@coderpush.com", "leo@coderpush.com", "hoangminh@coderpush.com", "quang@coderpush.com", "thinh@coderpush.com", "khanh@coderpush.com", "truong@coderpush.com", "son@coderpush.com", "trang@coderpush.com", "ruby@coderpush.com", "james@coderpush.com", "ha.nguyen@coderpush.com", "thanh@coderpush.com", "vinh.duong@coderpush.com", "hien@coderpush.com", "phong@coderpush.com", "nghia.huynh@coderpush.com", "john@coderpush.com", "sieu@coderpush.com", "huy.le@coderpush.com", "phi@coderpush.com", "thong.dang@coderpush.com", "nam@coderpush.com", "thuhien@coderpush.com", "diep@coderpush.com", "cuong@coderpush.com", "vanhung@coderpush.com", "anh@coderpush.com", "viet@coderpush.com", "chau@coderpush.com", "caochau@coderpush.com", "uyen@coderpush.com", "loan@coderpush.com", "quy.nguyen@coderpush.com", "kimlong@coderpush.com", "min@coderpush.com", "dao.mai@coderpush.com", "dat.nguyen@coderpush.com", "ha.pham@coderpush.com", "thientran@coderpush.com", "minhhung@coderpush.com", "thien.kieu@coderpush.com", "tron@coderpush.com", "vinh.tran@coderpush.com", "diem@coderpush.com", "huyen@coderpush.com", "harley@coderpush.com", "thien.huynh@coderpush.com", "kelly@coderpush.com", "hung.dang@coderpush.com", "oai@coderpush.com", "long@coderpush.com", "duy@coderpush.com", "ngan@coderpush.com", "nhi@coderpush.com", "tri.nguyen@coderpush.com", "long.truong@coderpush.com", "si@coderpush.com", "anne@coderpush.com", "hanna@coderpush.com", "hugh@coderpush.com", "thanh.le@coderpush.com"])
    }],
    "Duy x Leo 1-1" => [{
      :count => 1,
      :attendees => Set.new(["duy@coderpush.com", "leo@coderpush.com"])
    },
    {
      :count => 1,
      :attendees => Set.new(["johndoe@coderpush.com", "leo@coderpush.com"])
    }],
    "1-1 Duy/ThienK" => [
      {
        :count => 1,
        :attendees => Set.new(["duy@coderpush.com", "thien.kieu@coderpush.com"])
      },
      {
        :count => 1,
        :attendees => Set.new(["elise@coderpush.com", "thien.kieu@coderpush.com"])
      },
      {
        :count => 1,
        :attendees => Set.new(["sam@coderpush.com", "thien.kieu@coderpush.com"])
      }
    ],
    
  }

  def convert_to_table_summary(filtered_events_summary)
    # Create a header for the table
    puts "filtered_events_summary"
    puts filtered_events_summary
    # all_people_mails = ["amy@coderpush.com", "duy@coderpush.com", "alex@coderpush.com", "thien.kieu@coderpush.com", "leo@coderpush.com", "elise@coderpush.com", "sam@coderpush.com", "johndoe@coderpush.com", "brook@coderpush.com"]
    coderpusher_emails = [
      "minhhung@coderpush.com",
      "min@coderpush.com",
      "caochau@coderpush.com",
      "nhatanh@coderpush.com",
      "quang@coderpush.com",
      "kelly@coderpush.com",
      "nhat@coderpush.com",
      "vinh.duong@coderpush.com",
      "nghia.huynh@coderpush.com",
      "thien.huynh@coderpush.com",
      "bsu@coderpush.com",
      "truong@coderpush.com",
      "huy.le@coderpush.com",
      "thanh.le@coderpush.com",
      "dao.mai@coderpush.com",
      "thinh@coderpush.com",
      "vi@coderpush.com",
      "phi@coderpush.com",
      "quy.nguyen@coderpush.com",
      "hoangminh@coderpush.com",
      "nam@coderpush.com",
      "james@coderpush.com",
      "tri.nguyen@coderpush.com",
      "diem@coderpush.com",
      "ngan@coderpush.com",
      "uyen@coderpush.com",
      "dat.nguyen@coderpush.com",
      "nhi@coderpush.com",
      "ha.pham@coderpush.com",
      "hieu.pham@coderpush.com",
      "sieu@coderpush.com",
      "vinh.tran@coderpush.com",
      "duy@coderpush.com",
      "phong@coderpush.com",
      "thuhien@coderpush.com",
      "kimlong@coderpush.com",
      "thong.dang@coderpush.com",
      "vanhung@coderpush.com",
      "viet@coderpush.com",
      "long.truong@coderpush.com",
      "oai@coderpush.com",
      "tron@coderpush.com",
      "hung.dang@coderpush.com",
      "thientran@coderpush.com",
      "khanh@coderpush.com",
      "john@coderpush.com",
      "du@coderpush.com",
      "hien@coderpush.com",
      "loan@coderpush.com",
      "dieuhuyen@coderpush.com",
      "thanh@coderpush.com",
      "son@coderpush.com",
      "ha.nguyen@coderpush.com",
      "hanna@coderpush.com",
      "hugh@coderpush.com",
      "trang@coderpush.com",
      "chau@coderpush.com",
      "cong@coderpush.com",
      "huyen@coderpush.com",
      "ruby@coderpush.com",
      "si@coderpush.com",
    ]


    all_people_mails = coderpusher_emails

    content = ''
    
    header_str = "# | Manager               | Scheduled                | Unscheduled\n"
    content += header_str
    # puts "# | Manager               | Scheduled                | Unscheduled"
    # Iterate over each event in filtered_events_summary and track the index
    filtered_events_summary.each_with_index do |(event_name, occurrences), index|
      # Initialize variables to store manager and scheduled attendees
      manager_email = ""
      scheduled_attendees = []
      unscheduled_attendees = []

      # Iterate over each occurrence of the event
      occurrences.each do |occurrence|
        # Check if the occurrence has a manager field
        if occurrence.key?(:manager)
          # Set the manager's email
          manager_email = occurrence[:manager]
        end

        # Add attendees to the scheduled attendees list, excluding the manager
        scheduled_attendees.concat(occurrence[:attendees].reject { |attendee| attendee == manager_email })
      end

      # Remove duplicates from the scheduled attendees list
      scheduled_attendees.uniq!
      
      # Get unscheduled attendees
      unscheduled_attendees = all_people_mails - [manager_email] - scheduled_attendees

      # Print the table row
      row_str = "#{index + 1} | #{manager_email.ljust(21)} | #{scheduled_attendees.join(', ').ljust(25)} | #{unscheduled_attendees.join(', ').ljust(25)} |\n"
      # puts row_str
      content += row_str
    end

    return content
  end


  def format_events_summary(events_summary)
    puts "events_summary"
    puts events_summary
    filtered_events_summary = events_summary.select { |event_name, info| event_name.include?("1-1") }
    puts "filtered_events_summary"
    puts filtered_events_summary

    # Initialize an empty hash to store the most common email for each event
    most_common_emails = {}

    # Iterate over each event in filtered_events_summary
    filtered_events_summary.each do |event_name, occurrences|
      # Initialize an empty hash to store the count of attendees' emails for the current event
      email_count = Hash.new(0)

      # Iterate over each occurrence of the event
      occurrences.each do |occurrence|
        # Iterate over each attendee in the occurrence
        occurrence[:attendees].each do |email|
          # Increment the count of the attendee's email
          email_count[email] += 1
        end
      end

      # Find the email with the highest count (the most occurrences) for the current event
      most_common_email = email_count.max_by { |email, count| count }.first
      
      occurrences.each do |occurrence|
        occurrence[:manager] = most_common_email
    end

    # Assign the most common email for the current event to the most_common_emails hash
    most_common_emails[event_name] = most_common_email
    puts "here"
    puts filtered_events_summary

    return convert_to_table_summary(filtered_events_summary)
  end
end





# begin
#   subject = "Summary of all meetings this month"
#   body = "New body"
#   send_email(from_email, to_email, subject, body)
# end

begin
  service = authorize_and_load_client
  handle_events(service)
rescue Google::Apis::ClientError => e
  puts "Error: #{e}"
end


# Authorization code
# Please copy this code, switch to your application and paste it there
# 4/1AfJohXkdi6UscQf8r8fxGl47dPYZ_UGOSCpTXTF1jL5Oyj1bAccJVbI3k0U

# gem install google-auth
# gem install google-api-client
# gem install mail


## johndoe@gmail.com  |  1-1 meeting | 4

## Proton mail:
## cp_mailbot@proton.me
## 12345678