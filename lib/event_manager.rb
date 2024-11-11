require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def move_data_to_hdd(data,location)
  File.open("#{location}","w") do |file|
        file.puts data
    end
end

def generate_attendee_personal_data_in_hard_drive(attendee,ateendees_data_dir_name)
  id = attendee[0]
  attendee_directory_name = "#{ateendees_data_dir_name}/#{id}"
  Dir.mkdir("#{attendee_directory_name}") unless Dir.exist?("#{attendee_directory_name}")
  
  generate_phone_number(attendee,attendee_directory_name)
  generate_letter(attendee,attendee_directory_name) 
end

def generate_phone_number(attendee,attendee_directory_name)
    phone_number = generate_attendee_phone_number(attendee)
    location = "#{attendee_directory_name}/phone_number"

    move_data_to_hdd(phone_number,location)
end

def generate_attendee_phone_number(attendee)
    phone_number = clean_phone_number(attendee[:homephone])
end

def clean_phone_number (phone_number)
  phone_number = phone_number.delete('^0-9')
  number = phone_number.length
  if number < 10
    phone_number = ''
  elsif number > 10
    if number == 11 && phone_number[0] = '1'
      phone_number = phone_number[1..-1]
    else
      phone_number = ''
    end
  end
  phone_number
end

def generate_letter(attendee,attendee_directory_name)
  form_letter = generate_attendee_letter(attendee)
  location = "#{attendee_directory_name}/thanks.html"

  move_data_to_hdd(form_letter,location)
end

def generate_attendee_letter(attendee)
  template_text = File.read('form_letter.erb')
  erb_template = ERB.new template_text

  name = attendee[:first_name]
  zipcode = clean_zipcode(attendee[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def generate_attendee_advertising_data_in_hard_drive(attendee,advertising_data_hash) 
  generate_hours_realted_data(attendee,advertising_data_hash)
  
  generate_days_of_week_realted_data(attendee,advertising_data_hash)
end

def create_DateTime_object(string)
  DateTime.strptime(string, '%m/%d/%Y %H:%M')
end

def sort_hash_by_value_desc(hash)
  hash.sort_by{|k,v| -v}.to_h
end

def generate_hours_realted_data(attendee,advertising_data_hash)
  peak_hours = find_peak_registration_hours(attendee,advertising_data_hash)
end

def find_peak_registration_hours(atattendee,advertising_data_hash)
  date_and_hour_object = create_DateTime_object(attendee[:regdate])
  hour = date_and_hour_object.hour 
  hours_of_the_day[hour] += 1


  hours_of_the_day = sort_hash_by_value_desc(hours_of_the_day)

  string_to_add = ""
  hours_of_the_day = hours_of_the_day.map do |k,v|
    string_to_add = k <= 12 ? "am" : "pm"
    "#{k}#{string_to_add} number of registreted users at this hours is #{v}"
  end
end

def generate_days_of_week_realted_data(advertising_data_dir_name,attendee)
  peak_week_days = find_peak_days(attendee)
  location = "#{advertising_data_dir_name}/peak_days"

  move_data_to_hdd(peak_week_days,location)
end

def find_peak_days(attendee)
  date_and_hour_object = create_DateTime_object(attendee[:regdate])
  p date_and_hour_object
  day_of_the_week = date_and_hour_object.strftime("%A") 
  days_of_the_week[day_of_the_week] += 1

  days_of_the_week = sort_hash_by_value_desc(days_of_the_week)

  days_of_the_week = days_of_the_week.map do |day,number_of_users|
    "#{day} number of users that regisrated on this day is #{number_of_users}"
  end
end

puts 'EventManager initialized.'

attendees_collection = CSV.read(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

ateendees_data_dir_name = attendees_data
Dir.mkdir("#{ateendees_data_dir_name}") unless Dir.exist?("#{ateendees_data_dir_name}")

advertising_data_dir_name = "advertising_data"
Dir.mkdir("#{advertising_data_dir_name}") unless Dir.exist?("#{advertising_data_dir_name}")

advertising_data_hash = {hours_of_the_day = {}, days_of_the_week = {}}
# genrate hours of day hash
  all_possible_hours_in_a_day = 25 
  all_possible_hours_in_a_day.times do |hour|
    advertising_data_hash[hours_of_the_day[hour]] = 0 
  end
# generate days of week hash
 all_possible_days_of_the_week = Date::DAYNAMES
  all_possible_days_of_the_week.each do |day|
    advertising_data_hash[days_of_the_week[day]] = 0
  end

attendees_collection.each do |attendee|
  generate_attendee_personal_data_in_hard_drive(attendee,ateendees_data_dir_name)

  generate_attendee_advertising_data_in_hard_drive(attendee,advertising_data_hash)
end







