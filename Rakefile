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
end
