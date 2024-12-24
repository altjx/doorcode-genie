# Automated Lock Management Script

## Overview
This script automates door code management for properties managed through OwnerRez, using Seam's API integration with door locks. It is designed to be run as a cron job to manage access codes for check-ins and check-outs seamlessly.

The script was created as a solution for users who want to use door locks with OwnerRez, which does not natively support such locks. By leveraging Seam's free API, this script facilitates automated lock operations without replacing existing hardware.

## Features
- Fetches bookings from OwnerRez.
- Manages access codes for arrivals and departures using Seam.
- Sends SMS notifications using Twilio.
- Allows configurable departure time thresholds.
- **Docker Support:**
  - Dockerized version of the script.
  - Environment variables can be managed via an `.env` file.
  - Cron job is automatically set to run every hour.

## Configuration

### Required Environment Variables
The following environment variables need to be set:

- `SEAM_API_KEY`: Your Seam API key.
- `OWNERREZ_USERNAME`: Your OwnerRez username.
- `OWNERREZ_API_TOKEN`: Your OwnerRez API token.
- `TWILIO_ACCOUNT_SID`: Your Twilio account SID.
- `TWILIO_AUTH_TOKEN`: Your Twilio authentication token.
- `TWILIO_FROM_NUMBER`: The Twilio phone number used to send SMS notifications.
- `NOTIFICATION_PHONE_NUMBERS`: A comma-separated list of recipient phone numbers for SMS notifications.

### Configurable Parameters
- `DEPARTURE_TIME_THRESHOLD`: This value determines the time (in 24-hour format) after which departing guests' access codes are removed. By default, it is set to `16` (4 PM). Adjust this value in the script as needed:
  ```ruby
  DEPARTURE_TIME_THRESHOLD = 16
  ```
- Replace `<Name of house configured for door lock>` with the actual name of your house as configured in your Seam account in the following line:
  ```ruby
  target_door_lock = seam.locks.list.find do |lock|
    lock.properties.august_metadata.house_name == '<Name of house configured for door lock>'
  end
  ```

## Installation

### Without Docker
1. Clone this repository:
   ```bash
   git clone https://github.com/altjx/doorcode-genie.git
   cd doorcode-genie
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Configure environment variables as described above.

4. Schedule the script as a cron job. For example, to run every 1hr:
   ```cron
   0 * * * * /path/to/ruby /path/to/script.rb
   ```

### With Docker
1. Build the Docker image:
   ```bash
   docker-compose build
   ```

2. Configure your `.env` file with the required environment variables:
   ```env
   SEAM_API_KEY=your_seam_api_key
   PROPERTY_ID=123456
   OWNERREZ_USERNAME=your_username
   OWNERREZ_API_TOKEN=your_api_token
   OWNERREZ_BASE_URL=https://api.ownerreservations.com/v2
   TWILIO_ACCOUNT_SID=your_twilio_account_sid
   TWILIO_AUTH_TOKEN=your_twilio_auth_token
   TWILIO_FROM_NUMBER=your_twilio_phone_number
   NOTIFICATION_PHONE_NUMBERS=recipient_phone_number_1,recipient_phone_number_2
   ```

3. Run the container:
   ```bash
   docker-compose up -d
   ```

4. The cron job inside the container will automatically run the script every hour. Logs can be monitored in the container's log files:
   ```bash
   docker logs doorcode-genie
   ```

## Usage

### Manual Run
To run the script manually, execute the following command:
```bash
ruby script.rb
```

### Docker Logs
To check the execution logs when using Docker, run:
```bash
   docker logs doorcode-genie
```

## References
- [OwnerRez API Documentation](https://www.ownerreservations.com/support/articles/api-documentation)
- [Seam API Documentation](https://docs.seam.co/)

## License
This project is licensed under the [Unlicense](LICENSE), allowing free use, modification, and distribution.

## Acknowledgments
- [OwnerRez](https://www.ownerreservations.com/)
- [Seam API](https://www.seam.co/)
- [Twilio](https://www.twilio.com/)

