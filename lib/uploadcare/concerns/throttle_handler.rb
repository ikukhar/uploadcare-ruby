# frozen_string_literal: true

module Uploadcare
  # This module lets clients send request multiple times if request is throttled
  module ThrottleHandler
    ATTEMPTS = 5

    # call given block. If ThrottleError is returned, it will wait and attempt again 4 more times

    def handle_throttling
      (ATTEMPTS - 1).times do
        begin
          return yield
        rescue(ThrottleError) => error
          wait_time = error.timeout
          sleep(wait_time)
          next
        end
      end
      yield
    end
  end
end
