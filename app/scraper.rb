require_relative 'environment'

def scraper_main_parts
  make_requests
end

def run_scraper
  @makler_log.info "**********************************************"
  @makler_log.info "**********************************************"

  @start = Time.now
  @scraper_report = ScraperReport.new(@statistics_sheet, @error_sheet)

  begin
    scraper_main_parts
  rescue StandardError => e
    puts 'Scraper stopped due to error --- Check email report for details'

    error_message = e.to_s.empty? ? 'No message' : e.to_s
    @makler_log.error("Scraper stopped mid-run due to error: #{error_message}")
    @makler_log.error('ERROR BACKTRACE:')
    e.backtrace.each do |backtrace_line|
      @makler_log.error(backtrace_line)
    end
  end

  @statistics_sheet.end_scrape_now
  @scraper_report.send_email
end

def test_run_scraper
  if environment_is_production
    puts 'Test runs are not allowed on production environment'
    puts 'Please change ENVIRONMENT in .env file to not be "production"'
    exit
  end

  # Start with empty status file
  @status.reset_file

  # Limit number of ads to be scraped
  @max_num_ids_to_scrape = 20

  # Begin scraper run
  run_scraper

  # Running the scraper for real updates status file and the db dump file
  # Checking out the files here prevents them from accidentally getting
  # committed
  git_checkout_file(@status_file_name)
  git_checkout_file(@db_dump_file)
end

def run_scraper_from_page(start_page_num)
  @start_page_num = start_page_num
  run_scraper
end
