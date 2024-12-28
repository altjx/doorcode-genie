# frozen_string_literal: true

require 'httparty'
require 'date'
require 'seam'
require 'twilio-ruby'

# Configure Seam API key
SEAM_API_KEY = ENV['SEAM_API_KEY'] || '<my code here>'
PROPERTY_ID = ENV['PROPERTY_ID'] || 123456
OWNERREZ_USERNAME = ENV['OWNERREZ_USERNAME'] || '<your_username>'
OWNERREZ_API_TOKEN = ENV['OWNERREZ_API_TOKEN'] || '<your_api_token>'
OWNERREZ_BASE_URL = ENV['OWNERREZ_BASE_URL'] || 'https://api.ownerreservations.com'

# Twilio credentials
TWILIO_ACCOUNT_SID = ENV['TWILIO_ACCOUNT_SID'] || '<your_twilio_account_sid>'
TWILIO_AUTH_TOKEN = ENV['TWILIO_AUTH_TOKEN'] || '<your_twilio_auth_token>'
TWILIO_FROM_NUMBER = ENV['TWILIO_FROM_NUMBER'] || '<your_twilio_phone_number>'
NOTIFICATION_PHONE_NUMBERS = (ENV['NOTIFICATION_PHONE_NUMBERS']&.split(',') || ['<recipient_phone_number_1>', '<recipient_phone_number_2>']).freeze

# Time threshold for departing guest actions
DEPARTURE_TIME_THRESHOLD = 16

# Initialize Seam
seam = Seam.new(api_key: SEAM_API_KEY)
target_door_lock = seam.locks.list.find do |lock|
  lock.properties.august_metadata.house_name == '<Name of house configured for door lock>'
end

# Twilio client
@twilio_client = Twilio::REST::Client.new(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)

# Send SMS notification
def send_sms(message)
  NOTIFICATION_PHONE_NUMBERS.each do |number|
    @twilio_client.messages.create(
      from: TWILIO_FROM_NUMBER,
      to: number,
      body: message
    )
  end
end

# Fetch bookings from OwnerRez
def fetch_bookings
  auth = { username: OWNERREZ_USERNAME, password: OWNERREZ_API_TOKEN }

  all_items = []
  next_page_url = nil

  loop do
    # Construct the full URL for the current request
    current_url = next_page_url ? "#{OWNERREZ_BASE_URL}#{next_page_url}" : "#{OWNERREZ_BASE_URL}/v2/bookings?property_ids=#{PROPERTY_ID}"

    response = HTTParty.get(current_url, basic_auth: auth)
    parsed_response = response.parsed_response

    items = parsed_response['items']
    all_items.concat(items)

    # Get the next_page_url from the response
    next_page_url = parsed_response['next_page_url']

    # Break the loop if there is no next_page_url
    break unless next_page_url
  end

  all_items
end

# Fetch guest details
def fetch_guest(guest_id)
  url = "#{OWNERREZ_BASE_URL}/v2/guests/#{guest_id}"
  auth = { username: OWNERREZ_USERNAME, password: OWNERREZ_API_TOKEN }
  response = HTTParty.get(url, basic_auth: auth)
  response.parsed_response
end

# Get last 4 digits of guest's phone number
def extract_door_code(guest)
  phone_number = guest['phones']&.find { |phone| phone['is_default'] }&.dig('number') || guest['phones'].first['number']
  phone_number[-4..]
end

# Create access code for arriving guests
def add_door_code(seam, target_door_lock, code, name)
  seam.access_codes.create(
    device_id: target_door_lock.device_id,
    code: code,
    name: name
  )
  send_sms("Door code added for #{name}: #{code}")
end

# Delete access code for departing guests
def delete_door_code(seam, target_door_lock, name)
  list_of_codes = seam.access_codes.list(device_id: target_door_lock.device_id)
  code_to_delete = list_of_codes.find { |code| code.name == name }
  return unless code_to_delete

  seam.access_codes.delete(
    device_id: target_door_lock.device_id,
    access_code_id: code_to_delete.access_code_id
  )
  send_sms("Door code removed for #{name}")
end

# Main processing
bookings = fetch_bookings
current_time = Time.now

def process_bookings(bookings, current_time, seam, target_door_lock)
  bookings.each do |booking|
    arrival_date = Date.parse(booking['arrival'])
    departure_date = Date.parse(booking['departure'])
    guest_id = booking['guest_id']

    # Skip if the arrival is not for today
    # Skip if the departure is for today but the current time is before 4 PM
    unless arrival_date == Date.today || (departure_date == Date.today && current_time.hour >= DEPARTURE_TIME_THRESHOLD)
      next
    end

    guest = fetch_guest(guest_id)
    door_code = extract_door_code(guest)
    guest_name = "#{guest['first_name']} #{guest['last_name']}"

    if arrival_date == Date.today
      # Add code for arriving guests
      add_door_code(seam, target_door_lock, door_code, guest_name)
      puts "Added door code for #{guest_name}: #{door_code}"
    elsif departure_date == Date.today && current_time.hour >= DEPARTURE_TIME_THRESHOLD
      # Remove code for departing guests
      delete_door_code(seam, target_door_lock, guest_name)
      puts "Deleted door code for #{guest_name}: #{door_code}"
    end
  end
end

process_bookings(bookings, current_time, seam, target_door_lock)
