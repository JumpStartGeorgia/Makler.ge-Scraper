require_relative 'app/scraper'

namespace :scraper do
  desc 'Run scraper'
  task :run do
    run_scraper
  end

  desc 'Test run scraper'
  task :test_run do
    run_scraper(
      fail_on_production: true,
      start_with_default_status: true,
      max_num_ids_to_scrape: 20,
      checkout_status_file: true,
      checkout_db_dump_file: true)
  end

  namespace :schedule do
    desc 'Schedule cron job to scrape daily at 4 AM'
    task :run_daily do
      `bundle exec whenever -w`
    end
  end

  # Useful if data has not been gathered for a long period, and you want to
  # break up getting the old data into multiple scraper runs
  desc 'Run scraper, but start gathering IDs at specified page'
  task :run_from_page, [:start_page_num] do |_t, args|
    start_page_num = args[:start_page_num].to_i

    run_scraper(
      start_from_page: start_page_num)
  end
end

namespace :database do
  desc 'Print out number of posts by date'
  task :number_postings_by_date do
    puts @postings_database.number_postings_by_date
  end
end

namespace :data do
  desc 'Compress all files in data directory'
  task :compress_files do
    compress_data_files
  end
end

namespace :status do
  desc 'Reset status file'
  task :reset do
    @status.reset_file
  end
end
