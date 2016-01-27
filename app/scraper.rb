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

  # limit number of ids
  @max_num_ids_to_scrape = 20

  make_requests

  # Running the scraper for real updates status file and the db dump file
  # Checking out the files here prevents them from accidentally getting
  # committed
  git_checkout_file(@status_file)
  git_checkout_file(@db_dump_file)
end
