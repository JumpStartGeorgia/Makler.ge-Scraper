require 'pry-byebug'
require_relative 'makler'

def run_scraper
  make_requests
end

def test_run_scraper
  if environment_is_production
    puts 'Test runs are not allowed on production environment'
    puts 'Please change ENVIRONMENT in .env file to not be "production"'
    exit
  end

  reset_status
  @max_num_ids_to_scrape = 20
  make_requests
end
