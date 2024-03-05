require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/calendar_v3'
require 'fileutils'
require 'date'
require 'active_support/all'
require 'mail'
require 'set'
require 'text-table'
require 'json'

# service_account_id = "duyserviceaccountcalendar"
# service_account_mail = "duyserviceaccountcalendar@gg-calendar-ruby.iam.gserviceaccount.com"

# Replace these variables with your service account credentials and the email address
SERVICE_ACCOUNT_EMAIL = 'duyserviceaccountcalendar@gg-calendar-ruby.iam.gserviceaccount.com'
SERVICE_ACCOUNT_FILE = './gg-calendar-ruby-service-account.json'
# CALENDAR_ID = 'primary' # Use 'primary' for the primary calendar
CALENDAR_ID = 'duy@coderpush.com' # Use 'primary' for the primary calendar


def merge_sets(*sets)
  merged_array = []
  sets.each do |set|
    merged_array.concat(set.to_a)
  end
  merged_array
end

# Set up email delivery method
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
  calendar = Google::Apis::CalendarV3::CalendarService.new
  calendar.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open(SERVICE_ACCOUNT_FILE),
    scope: Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY
  )
  
  # Get all events for the specified calendar
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

  return events
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

  events_summary = Hash.new { |hash, key| hash[key] = [] }
  puts "- events_summary"
  puts events_summary

  response.items.each do |event|
    summary = event.summary
    attendees = event.attendees || []
  
    # Add each event summary as an object to the array under the summary key
    events_summary[summary] << { count: 1, attendees: attendees.map { |attendee| attendee.email.to_s } }
  end
  

  month_name = Time.now.strftime("%B") # Get the full month name
  puts "\nSummary of events in #{month_name}:"

  sample_events_summary = {"Dux-soup - Daily Sync"=>[{:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "harley@coderpush.com"]}], "🧑‍💻🏊🚵🏃 Committee V3.0 "=>[{:count=>1, :attendees=>["hieu.pham@coderpush.com", "nhat@coderpush.com", "cong@coderpush.com", "du@coderpush.com", "coral@coderpush.com", "vi@coderpush.com", "dieuhuyen@coderpush.com", "bsu@coderpush.com", "nhatanh@coderpush.com", "leo@coderpush.com", "hoangminh@coderpush.com", "quang@coderpush.com", "thinh@coderpush.com", "khanh@coderpush.com", "truong@coderpush.com", "son@coderpush.com", "ruby@coderpush.com", "james@coderpush.com", "ha.nguyen@coderpush.com", "thanh@coderpush.com", "vinh.duong@coderpush.com", "hien@coderpush.com", "phong@coderpush.com", "nghia.huynh@coderpush.com", "john@coderpush.com", "sieu@coderpush.com", "huy.le@coderpush.com", "phi@coderpush.com", "thong.dang@coderpush.com", "nam@coderpush.com", "thuhien@coderpush.com", "diep@coderpush.com", "cuong@coderpush.com", "vanhung@coderpush.com", "anh@coderpush.com", "viet@coderpush.com", "chau@coderpush.com", "caochau@coderpush.com", "uyen@coderpush.com", "loan@coderpush.com", "quy.nguyen@coderpush.com", "kimlong@coderpush.com", "min@coderpush.com", "dao.mai@coderpush.com", "dat.nguyen@coderpush.com", "ha.pham@coderpush.com", "thientran@coderpush.com", "minhhung@coderpush.com", "thien.kieu@coderpush.com", "tron@coderpush.com", "vinh.tran@coderpush.com", "diem@coderpush.com", "huyen@coderpush.com", "harley@coderpush.com", "kelly@coderpush.com", "hung.dang@coderpush.com", "oai@coderpush.com", "long@coderpush.com", "duy@coderpush.com", "ngan@coderpush.com", "nhi@coderpush.com", "thien.huynh@coderpush.com", "trang@coderpush.com", "tri.nguyen@coderpush.com", "long.truong@coderpush.com", "si@coderpush.com", "hanna@coderpush.com", "thanh.le@coderpush.com", "hugh@coderpush.com", "maianh@coderpush.com"]}, {:count=>1, :attendees=>["hieu.pham@coderpush.com", "nhat@coderpush.com", "cong@coderpush.com", "du@coderpush.com", "coral@coderpush.com", "vi@coderpush.com", "dieuhuyen@coderpush.com", "bsu@coderpush.com", "nhatanh@coderpush.com", "leo@coderpush.com", "hoangminh@coderpush.com", "quang@coderpush.com", "thinh@coderpush.com", "khanh@coderpush.com", "truong@coderpush.com", "son@coderpush.com", "ruby@coderpush.com", "james@coderpush.com", "ha.nguyen@coderpush.com", "thanh@coderpush.com", "vinh.duong@coderpush.com", "hien@coderpush.com", "phong@coderpush.com", "nghia.huynh@coderpush.com", "john@coderpush.com", "sieu@coderpush.com", "huy.le@coderpush.com", "phi@coderpush.com", "thong.dang@coderpush.com", "nam@coderpush.com", "thuhien@coderpush.com", "diep@coderpush.com", "cuong@coderpush.com", "vanhung@coderpush.com", "anh@coderpush.com", "viet@coderpush.com", "chau@coderpush.com", "caochau@coderpush.com", "uyen@coderpush.com", "loan@coderpush.com", "quy.nguyen@coderpush.com", "kimlong@coderpush.com", "min@coderpush.com", "dao.mai@coderpush.com", "dat.nguyen@coderpush.com", "ha.pham@coderpush.com", "thientran@coderpush.com", "minhhung@coderpush.com", "thien.kieu@coderpush.com", "tron@coderpush.com", "vinh.tran@coderpush.com", "diem@coderpush.com", "huyen@coderpush.com", "harley@coderpush.com", "kelly@coderpush.com", "hung.dang@coderpush.com", "oai@coderpush.com", "long@coderpush.com", "duy@coderpush.com", "ngan@coderpush.com", "nhi@coderpush.com", "thien.huynh@coderpush.com", "trang@coderpush.com", "tri.nguyen@coderpush.com", "long.truong@coderpush.com", "si@coderpush.com", "hanna@coderpush.com", "thanh.le@coderpush.com", "hugh@coderpush.com", "maianh@coderpush.com"]}, {:count=>1, :attendees=>["hieu.pham@coderpush.com", "nhat@coderpush.com", "cong@coderpush.com", "du@coderpush.com", "coral@coderpush.com", "vi@coderpush.com", "dieuhuyen@coderpush.com", "bsu@coderpush.com", "nhatanh@coderpush.com", "leo@coderpush.com", "hoangminh@coderpush.com", "quang@coderpush.com", "thinh@coderpush.com", "khanh@coderpush.com", "truong@coderpush.com", "son@coderpush.com", "ruby@coderpush.com", "james@coderpush.com", "ha.nguyen@coderpush.com", "thanh@coderpush.com", "vinh.duong@coderpush.com", "hien@coderpush.com", "phong@coderpush.com", "nghia.huynh@coderpush.com", "john@coderpush.com", "sieu@coderpush.com", "huy.le@coderpush.com", "phi@coderpush.com", "thong.dang@coderpush.com", "nam@coderpush.com", "thuhien@coderpush.com", "diep@coderpush.com", "cuong@coderpush.com", "vanhung@coderpush.com", "anh@coderpush.com", "viet@coderpush.com", "chau@coderpush.com", "caochau@coderpush.com", "uyen@coderpush.com", "loan@coderpush.com", "quy.nguyen@coderpush.com", "kimlong@coderpush.com", "min@coderpush.com", "dao.mai@coderpush.com", "dat.nguyen@coderpush.com", "ha.pham@coderpush.com", "thientran@coderpush.com", "minhhung@coderpush.com", "thien.kieu@coderpush.com", "tron@coderpush.com", "vinh.tran@coderpush.com", "diem@coderpush.com", "huyen@coderpush.com", "harley@coderpush.com", "kelly@coderpush.com", "hung.dang@coderpush.com", "oai@coderpush.com", "long@coderpush.com", "duy@coderpush.com", "ngan@coderpush.com", "nhi@coderpush.com", "thien.huynh@coderpush.com", "trang@coderpush.com", "tri.nguyen@coderpush.com", "long.truong@coderpush.com", "si@coderpush.com", "hanna@coderpush.com", "thanh.le@coderpush.com", "hugh@coderpush.com", "maianh@coderpush.com"]}, {:count=>1, :attendees=>["hieu.pham@coderpush.com", "nhat@coderpush.com", "cong@coderpush.com", "du@coderpush.com", "coral@coderpush.com", "vi@coderpush.com", "dieuhuyen@coderpush.com", "bsu@coderpush.com", "nhatanh@coderpush.com", "leo@coderpush.com", "hoangminh@coderpush.com", "quang@coderpush.com", "thinh@coderpush.com", "khanh@coderpush.com", "truong@coderpush.com", "son@coderpush.com", "ruby@coderpush.com", "james@coderpush.com", "ha.nguyen@coderpush.com", "thanh@coderpush.com", "vinh.duong@coderpush.com", "hien@coderpush.com", "phong@coderpush.com", "nghia.huynh@coderpush.com", "john@coderpush.com", "sieu@coderpush.com", "huy.le@coderpush.com", "phi@coderpush.com", "thong.dang@coderpush.com", "nam@coderpush.com", "thuhien@coderpush.com", "diep@coderpush.com", "cuong@coderpush.com", "vanhung@coderpush.com", "anh@coderpush.com", "viet@coderpush.com", "chau@coderpush.com", "caochau@coderpush.com", "uyen@coderpush.com", "loan@coderpush.com", "quy.nguyen@coderpush.com", "kimlong@coderpush.com", "min@coderpush.com", "dao.mai@coderpush.com", "dat.nguyen@coderpush.com", "ha.pham@coderpush.com", "thientran@coderpush.com", "minhhung@coderpush.com", "thien.kieu@coderpush.com", "tron@coderpush.com", "vinh.tran@coderpush.com", "diem@coderpush.com", "huyen@coderpush.com", "harley@coderpush.com", "kelly@coderpush.com", "hung.dang@coderpush.com", "oai@coderpush.com", "long@coderpush.com", "duy@coderpush.com", "ngan@coderpush.com", "nhi@coderpush.com", "thien.huynh@coderpush.com", "trang@coderpush.com", "tri.nguyen@coderpush.com", "long.truong@coderpush.com", "si@coderpush.com", "hanna@coderpush.com", "thanh.le@coderpush.com", "hugh@coderpush.com", "maianh@coderpush.com"]}, {:count=>1, :attendees=>["hieu.pham@coderpush.com", "nhat@coderpush.com", "cong@coderpush.com", "du@coderpush.com", "coral@coderpush.com", "vi@coderpush.com", "dieuhuyen@coderpush.com", "bsu@coderpush.com", "nhatanh@coderpush.com", "leo@coderpush.com", "hoangminh@coderpush.com", "quang@coderpush.com", "thinh@coderpush.com", "khanh@coderpush.com", "truong@coderpush.com", "son@coderpush.com", "ruby@coderpush.com", "james@coderpush.com", "ha.nguyen@coderpush.com", "thanh@coderpush.com", "vinh.duong@coderpush.com", "hien@coderpush.com", "phong@coderpush.com", "nghia.huynh@coderpush.com", "john@coderpush.com", "sieu@coderpush.com", "huy.le@coderpush.com", "phi@coderpush.com", "thong.dang@coderpush.com", "nam@coderpush.com", "thuhien@coderpush.com", "diep@coderpush.com", "cuong@coderpush.com", "vanhung@coderpush.com", "anh@coderpush.com", "viet@coderpush.com", "chau@coderpush.com", "caochau@coderpush.com", "uyen@coderpush.com", "loan@coderpush.com", "quy.nguyen@coderpush.com", "kimlong@coderpush.com", "min@coderpush.com", "dao.mai@coderpush.com", "dat.nguyen@coderpush.com", "ha.pham@coderpush.com", "thientran@coderpush.com", "minhhung@coderpush.com", "thien.kieu@coderpush.com", "tron@coderpush.com", "vinh.tran@coderpush.com", "diem@coderpush.com", "huyen@coderpush.com", "harley@coderpush.com", "kelly@coderpush.com", "hung.dang@coderpush.com", "oai@coderpush.com", "long@coderpush.com", "duy@coderpush.com", "ngan@coderpush.com", "nhi@coderpush.com", "thien.huynh@coderpush.com", "trang@coderpush.com", "tri.nguyen@coderpush.com", "long.truong@coderpush.com", "si@coderpush.com", "hanna@coderpush.com", "thanh.le@coderpush.com", "hugh@coderpush.com", "maianh@coderpush.com"]}], "Uống thuốc"=>[{:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}, {:count=>1, :attendees=>[]}], "Dux-Soup / CoderPush weekly meeting"=>[{:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "will@dux-soup.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "will@dux-soup.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "will@dux-soup.com"]}, {:count=>1, :attendees=>["thien.kieu@coderpush.com", "duy@coderpush.com", "will@dux-soup.com"]}], "🎙 Tech Talks "=>[{:count=>1, :attendees=>["hieu.pham@coderpush.com", "nhat@coderpush.com", "cong@coderpush.com", "du@coderpush.com", "vu@coderpush.com", "coral@coderpush.com", "vi@coderpush.com", "dieuhuyen@coderpush.com", "bsu@coderpush.com", "nhatanh@coderpush.com", "leo@coderpush.com", "hoangminh@coderpush.com", "quang@coderpush.com", "thinh@coderpush.com", "khanh@coderpush.com", "truong@coderpush.com", "son@coderpush.com", "trang@coderpush.com", "ruby@coderpush.com", "james@coderpush.com", "ha.nguyen@coderpush.com", "thanh@coderpush.com", "vinh.duong@coderpush.com", "hien@coderpush.com", "phong@coderpush.com", "nghia.huynh@coderpush.com", "john@coderpush.com", "sieu@coderpush.com", "huy.le@coderpush.com", "phi@coderpush.com", "thong.dang@coderpush.com", "nam@coderpush.com", "thuhien@coderpush.com", "diep@coderpush.com", "cuong@coderpush.com", "vanhung@coderpush.com", "anh@coderpush.com", "viet@coderpush.com", "chau@coderpush.com", "caochau@coderpush.com", "uyen@coderpush.com", "loan@coderpush.com", "quy.nguyen@coderpush.com", "kimlong@coderpush.com", "min@coderpush.com", "dao.mai@coderpush.com", "dat.nguyen@coderpush.com", "ha.pham@coderpush.com", "thientran@coderpush.com", "minhhung@coderpush.com", "thien.kieu@coderpush.com", "tron@coderpush.com", "vinh.tran@coderpush.com", "diem@coderpush.com", "huyen@coderpush.com", "harley@coderpush.com", "thien.huynh@coderpush.com", "kelly@coderpush.com", "hung.dang@coderpush.com", "oai@coderpush.com", "long@coderpush.com", "duy@coderpush.com", "ngan@coderpush.com", "nhi@coderpush.com", "tri.nguyen@coderpush.com", "long.truong@coderpush.com", "si@coderpush.com", "anne@coderpush.com", "hanna@coderpush.com", "hugh@coderpush.com", "thanh.le@coderpush.com"]}, {:count=>1, :attendees=>["hieu.pham@coderpush.com", "nhat@coderpush.com", "cong@coderpush.com", "du@coderpush.com", "vu@coderpush.com", "coral@coderpush.com", "vi@coderpush.com", "dieuhuyen@coderpush.com", "bsu@coderpush.com", "nhatanh@coderpush.com", "leo@coderpush.com", "hoangminh@coderpush.com", "quang@coderpush.com", "thinh@coderpush.com", "khanh@coderpush.com", "truong@coderpush.com", "son@coderpush.com", "trang@coderpush.com", "ruby@coderpush.com", "james@coderpush.com", "ha.nguyen@coderpush.com", "thanh@coderpush.com", "vinh.duong@coderpush.com", "hien@coderpush.com", "phong@coderpush.com", "nghia.huynh@coderpush.com", "john@coderpush.com", "sieu@coderpush.com", "huy.le@coderpush.com", "phi@coderpush.com", "thong.dang@coderpush.com", "nam@coderpush.com", "thuhien@coderpush.com", "diep@coderpush.com", "cuong@coderpush.com", "vanhung@coderpush.com", "anh@coderpush.com", "viet@coderpush.com", "chau@coderpush.com", "caochau@coderpush.com", "uyen@coderpush.com", "loan@coderpush.com", "quy.nguyen@coderpush.com", "kimlong@coderpush.com", "min@coderpush.com", "dao.mai@coderpush.com", "dat.nguyen@coderpush.com", "ha.pham@coderpush.com", "thientran@coderpush.com", "minhhung@coderpush.com", "thien.kieu@coderpush.com", "tron@coderpush.com", "vinh.tran@coderpush.com", "diem@coderpush.com", "huyen@coderpush.com", "harley@coderpush.com", "thien.huynh@coderpush.com", "kelly@coderpush.com", "hung.dang@coderpush.com", "oai@coderpush.com", "long@coderpush.com", "duy@coderpush.com", "ngan@coderpush.com", "nhi@coderpush.com", "tri.nguyen@coderpush.com", "long.truong@coderpush.com", "si@coderpush.com", "anne@coderpush.com", "hanna@coderpush.com", "hugh@coderpush.com", "thanh.le@coderpush.com"]}], "Duy x Leo 1-1"=>[{:count=>1, :attendees=>["duy@coderpush.com", "leo@coderpush.com"]}]}


  
  # output_str = format_events_summary(sample_events_summary)
  output_str = format_events_summary(events_summary)
  # output_str = format_events_summary(sample_events_summary)

  # subject = "Summary of 1-1 meetings"
  # body = output_str
  # send_email(subject, body)

  end



  def convert_to_table_summary(filtered_events_summary_param)
    # Create a header for the table
    puts filtered_events_summary_param
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

    manager_email = ["thien.kieu@coderpush.com", "leo@coderpush.com"]

    events_with_managers_participants = []

    filtered_events_summary = filtered_events_summary_param

    # Iterate through the events and their attendees
    filtered_events_summary.each do |event_name, event_data|
      managers = event_data.first[:attendees].select { |email| manager_email.include?(email) }
      # managers = event_data[:attendees].select { |email| manager_email.include?(email) }
      puts "Managers: #{managers}"
      # Get the list of participants by removing manager emails from the attendees
      participants = event_data.first[:attendees].reject { |email| manager_email.include?(email) }
      
      # # Create an object containing manager and participants for the event
      event_object = { "manager" => managers.join(", "), "participants" => participants.to_a }
      
      # # Add the event object to the array
      events_with_managers_participants << event_object
    end

    puts "events_with_managers_participants"
    puts events_with_managers_participants.inspect


    participants_grouped_by_manager = Hash.new { |hash, key| hash[key] = [] }

    # Iterate through each event object
    events_with_managers_participants.each do |event|
      # Extract manager and participants from the event object
      manager = event["manager"]
      participants = event["participants"]
      
      # Add participants to the group based on the manager
      participants_grouped_by_manager[manager] += participants
    end

    puts "participants_grouped_by_manager"
    puts participants_grouped_by_manager.inspect
  
    # Initialize an empty array to store the objects
    manager_employee_objects = []

    # Iterate through the hash and create objects
    participants_grouped_by_manager.each do |manager, participants|
      # Create an object with manager and employees
      manager_employee_object = {
        "manager" => manager,
        "scheduled" => participants
      }
      # Add the object to the array
      manager_employee_objects << manager_employee_object
    end

    puts "manager_employee_objects"
    puts manager_employee_objects.inspect


    # Initialize an empty array to store the objects
    manager_scheduled_objects_with_unscheduled = []

    # Iterate through the hash and create objects
    participants_grouped_by_manager.each do |manager, participants|
      # Find unscheduled emails
      unscheduled_emails = coderpusher_emails - participants - [manager]
      
      # Create an object with manager, scheduled, and unscheduled
      manager_scheduled_object = {
        "manager" => manager,
        "scheduled" => participants,
        "unscheduled" => unscheduled_emails
      }
      
      # Add the object to the array
      manager_scheduled_objects_with_unscheduled << manager_scheduled_object
    end

    puts manager_scheduled_objects_with_unscheduled.inspect

    table_str = convert_to_table(manager_scheduled_objects_with_unscheduled, 120)
    puts "table_str"
    puts table_str

    subject = "Summary of 1-1 meetings"
    body = table_str
    send_email(subject, body)
  end

 
def convert_to_table(array, max_width)
  # Function to pad a string to a given length
  pad_string = ->(str, length) { str.ljust(length) }

  # Calculate max content length for each column
  max_lengths = array.reduce({"Manager" => 0, "Scheduled" => 0, "Unscheduled" => 0}) do |max_lengths, item|
    max_lengths["Manager"] = [max_lengths["Manager"], item["manager"].length].max
    max_lengths["Scheduled"] = [max_lengths["Scheduled"], item["scheduled"].join(", ").length].max
    max_lengths["Unscheduled"] = [max_lengths["Unscheduled"], item["unscheduled"].join(", ").length].max
    max_lengths
  end

  # Adjust column widths based on max lengths and max table width
  total_width = max_lengths.values.sum + 10  # Add padding and separator widths
  width_ratio = max_width.to_f / total_width
  column_widths = max_lengths.transform_values { |length| (length * width_ratio).to_i }

  # Generate table header
  header = "| #{pad_string.call('Manager', column_widths["Manager"])} | #{pad_string.call('Scheduled', column_widths["Scheduled"])} | #{pad_string.call('Unscheduled', column_widths["Unscheduled"])} |"

  # Generate separator line
  separator = "+-#{'-' * column_widths["Manager"]}-+-#{'-' * column_widths["Scheduled"]}-+-#{'-' * column_widths["Unscheduled"]}-+"

  # Generate table rows
  rows = array.map do |item|
    "| #{pad_string.call(item["manager"], column_widths["Manager"])} | #{pad_string.call(item["scheduled"].join(", "), column_widths["Scheduled"])} | #{pad_string.call(item["unscheduled"].join(", "), column_widths["Unscheduled"])} |"
  end

  # Construct the final table string
  table_string = [separator, header, separator, rows.join("\n"), separator].join("\n")

  table_string
end



def format_events_summary(events_summary)
  filtered_events_summary = events_summary.select do |event_name, info|
    event_name && event_name.include?("1-1")
  end
  
  return convert_to_table_summary(filtered_events_summary.to_a)
end


begin
  events = initialize_calendar_service()
  events_summary = Hash.new { |hash, key| hash[key] = [] }

  events.each do |event|
    summary = event.summary
    attendees = event.attendees || []
  
    # Add each event summary as an object to the array under the summary key
    events_summary[summary] << { count: 1, attendees: attendees.map { |attendee| attendee.email.to_s } }
  end

  output_str = format_events_summary(events_summary)
end



