# Stores statistics about a scraper run
class StatisticsSheet
  def initialize
    @num_ids_processed = 0
    @num_ids_successfully_processed = 0
    @num_ids_timed_out = 0
    @num_ids_with_no_response = 0
    @num_ids_with_http_request_failure = 0
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

  attr_reader :num_ids_processed,
              :num_ids_successfully_processed,
              :num_ids_timed_out,
              :num_ids_with_no_response,
              :num_ids_with_http_request_failure

  def to_s
    <<-STRING
      Number of ids processed: #{num_ids_processed}
      Number of ids successfully processed: #{num_ids_successfully_processed}
      Number of ids timed out: #{num_ids_timed_out}
      Number of ids with no response: #{num_ids_with_no_response}
      Number of ids with http request failure: #{num_ids_with_http_request_failure}
    STRING
  end
end
