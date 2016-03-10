require_relative 'environment'

def scraper_main_parts
  @makler_log.info "**********************************************"
  @makler_log.info "**********************************************"

  @saved_ids_for_last_scraped_date = @postings_database.ids_for_date(
    @status.last_scraped_date
  )

  make_requests
end

def run_scraper(args = {})
  if args[:fail_on_production] && environment_is_production
    puts 'Test runs are not allowed on production environment'
    puts 'Please change ENVIRONMENT in .env file to not be "production"'
    exit
  end

  # Start with empty status file
  @status.reset_file if args[:start_with_default_status]

  # Limit number of ads to be scraped
  unless args[:max_num_ids_to_scrape].nil?
    @max_num_ids_to_scrape = args[:max_num_ids_to_scrape]
  end

  @start_page_num = args[:start_from_page] unless args[:start_from_page].nil?

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

  # Running the scraper for real updates status file and the db dump file
  # Checking out the files here prevents them from accidentally getting
  # committed
  git_checkout_file(@status_file_name) if args[:checkout_status_file]
  git_checkout_file(@db_dump_file) if args[:checkout_db_dump_file]
end
