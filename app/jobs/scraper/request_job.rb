module Scraper
  class RequestJob < ApplicationJob
    queue_as :default

    def perform(file)
      Scraper::Client.call(file)
    end

    handle_asynchronously :perform, :run_at => Proc.new { time_from_range.seconds.from_now }

    def error(job, exception)
      @exception = exception
    end

    def reschedule_at(attempts, time)
      if at_rate_limit?
        next_rate_limit_window
      end
    end

    def max_attempts
      if at_rate_limit?
        10
      else
        Delayed::Worker.max_attempts
      end
    end

    private

    def at_rate_limit?
      @exception.is_a?(Faraday::Error::ClientError) && @exception.response[:status] == 429
    end

    def next_rate_limit_window
      Time.now + time_from_range
    end

    def self.time_from_range
      rand(TMIN..TMAX)
    end
  end
end