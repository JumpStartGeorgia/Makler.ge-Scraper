require 'pry-byebug'
require_relative 'makler'

def run_scraper
  make_requests
end

def test_run_scraper
  reset_status
  make_requests
end
