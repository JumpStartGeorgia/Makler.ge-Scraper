require_relative 'environment'

# Stores statistics about a scraper run
class StatisticsSheet
  def initialize
    @start_time = Time.now
    @end_time = nil
    @num_ids_processed = 0
    @num_ids_successfully_processed = 0
    @num_ids_timed_out = 0
    @num_ids_with_no_response = 0
    @num_ids_with_http_request_failure = 0
    @num_db_records_saved = 0
    @num_duplicate_postings_found = 0
    @saved_records_start_date = nil
    @saved_records_end_date = nil
  end

  attr_reader :start_time,
              :end_time,
              :num_ids_processed,
              :num_ids_successfully_processed,
              :num_ids_timed_out,
              :num_ids_with_no_response,
              :num_ids_with_http_request_failure,
              :num_db_records_saved,
              :num_duplicate_postings_found,
              :saved_records_start_date,
              :saved_records_end_date

  def end_scrape_now
    @end_time = Time.now
  end

  def increase_num_ids_processed_by_1
    @num_ids_processed += 1
  end

  def increase_num_ids_successfully_processed_by_1
    @num_ids_successfully_processed += 1
  end

  def increase_num_ids_timed_out_by_1
    @num_ids_timed_out += 1
  end

  def increase_num_ids_with_no_response_by_1
    @num_ids_with_no_response += 1
  end

  def increase_num_ids_with_http_request_failure_by_1
    @num_ids_with_http_request_failure += 1
  end

  def increase_num_db_records_saved_by_1
    @num_db_records_saved += 1
  end

  def increase_num_duplicate_postings_found_by_1
    @num_duplicate_postings_found += 1
  end

  def update_saved_records_date_range(new_date)
    if saved_records_start_date.nil? || new_date < saved_records_start_date
      @saved_records_start_date = new_date
    elsif saved_records_end_date.nil? || new_date > saved_records_end_date
      @saved_records_end_date = new_date
    end
  end

  def scrape_duration
    return 'Start time not set' if start_time.nil?
    return 'End time not set' if end_time.nil?

    Time.at(end_time - start_time).utc.strftime("%H:%M:%S")
  end

  def to_s
    <<-STRING
      Scrape began: #{start_time}
      Scrape ended: #{end_time}
      Scrape duration: #{scrape_duration}

      --- Report on Requests Made to makler.ge ---
      Total number of duplicate postings found: #{num_duplicate_postings_found}
      Total number of ids processed: #{num_ids_processed}

      Number of ids successfully processed: #{num_ids_successfully_processed}
      Number of ids timed out: #{num_ids_timed_out}
      Number of ids with no response: #{num_ids_with_no_response}
      Number of ids with http request failure: #{num_ids_with_http_request_failure}

      --- Report on IDs Saved to Database ---

      Number of records saved to database: #{num_db_records_saved}
      Start date of saved records: #{saved_records_start_date}
      End date of saved records: #{saved_records_end_date}
    STRING
  end
end
