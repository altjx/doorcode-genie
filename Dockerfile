# Use a Ruby base image
FROM ruby:3.1-slim

# Set environment variables for non-interactive installations
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary system dependencies
RUN apt-get update && apt-get install -y \
    cron \
    git \
    build-essential \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy the Gemfile
COPY Gemfile ./

# Install Ruby gems and generate Gemfile.lock
RUN gem install bundler && bundle install

# Create a cron job to run the script every hour
RUN echo "0 * * * * root ruby /app/script.rb >> /var/log/doorcode-genie.log 2>&1" > /etc/cron.d/doorcode-genie

# Give execution rights to the cron job file
RUN chmod 0644 /etc/cron.d/doorcode-genie

# Apply the cron job
RUN crontab /etc/cron.d/doorcode-genie

# Expose the log file for debugging
VOLUME /var/log

# Start cron in the foreground
CMD ["cron", "-f"]
