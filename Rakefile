require_relative 'app/scraper'

namespace :scraper do
  desc 'Run scraper'
  task :run do
    run_scraper
  end

  desc 'Test run scraper'
  task :test_run do
    test_run_scraper
  end

  desc 'Compress all files in data directory'
  task :compress_data_files do
    compress_data_files
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
    run_scraper_from_page(args[:start_page_num].to_i)
  end
end

namespace :database do
  desc 'Print out number of posts by date'
  task :number_postings_by_date do
    puts @postings_database.number_postings_by_date
  end
end
