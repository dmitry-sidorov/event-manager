require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def prettify_phone_number(phone_number)
  "(#{phone_number[0..2]}) #{phone_number[3..5]}-#{phone_number[6..7]}-#{phone_number[8..9]}"
end

def clean_phone_number(phone_number)
  formatted_phone_number = phone_number.gsub(/\D+/, '')
  phone_length = formatted_phone_number.length

  if phone_length == 10
    prettify_phone_number(formatted_phone_number)
  elsif phone_length == 11 and formatted_phone_number[0] == '1'
    prettify_phone_number(formatted_phone_number[1..10])
  else
    nil
  end
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info
      .representative_info_by_address(
        address: zipcode,
        levels: 'country',
        roles: ['legislatorUpperBody', 'legislatorLowerBody'])
      .officials
  rescue
    legislator_names = "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exists? 'output'

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts "EventManager initialized!"

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
contents.each_with_index do |row, i|
  id = row[0]
  name = row[:first_name]
  zipcode=clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_number(row[:homephone])
  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
  puts "#{i} template created!"
end