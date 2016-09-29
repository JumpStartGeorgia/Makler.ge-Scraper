require_relative 'locales'

@statistics_sheet = StatisticsSheet.new

@data_files_log = CustomLogger.new('Data Files Log', 'data_files.log')
@missing_param_log = CustomLogger.new('Makler Missing Params Log', 'makler_missing_params.log')
@database_log = CustomLogger.new('Database Log', 'database.log')
@makler_log = CustomLogger.new('Makler Log', 'makler.log')

@error_sheet = ErrorSheet.new([
  @data_files_log,
  @missing_param_log,
  @database_log,
  @makler_log
])


# starting url
@posting_url = "http://makler.ge/?pg=ann&id="
@serach_url = "http://makler.ge/?pg=search&cat=-1&tp=-1&city_id=-1&raion_id=0&price_f=&price_t=&valuta=2&sart_f=&sart_t=&rooms_f=&rooms_t=&ubani_id=0&street_id=0&parti_f=&parti_t=&mdgomareoba=0&remont=0&project=0&xedi=0&metro_id=0&is_detailed_search=2&sb=d"
@page_param = "&p="
@lang_param = "&lan="

@finished_scraping_new_post_ids = false


####################################################
@nbsp = Nokogiri::HTML("&nbsp;").text
####################################################

# currenct exchange rates to dollar
@currencies = {}
@currencies['$'] = 1.00
@currencies['gel'] = 0.57 #1.75
@currencies['€'] = 1.38 #0.72

# the price for a place for rent and for sale include
# the price and the price per square meter
@sale_keys = [:for_sale, :for_lease]
@rent_keys = [:for_rent, :daily_rent]
@sq_m_keys = [:space, :land]
@address_key = :address

@non_number_price_text = ['Price Negotiable', 'ფასი შეთანხმებით']

@data_path = 'data/makler.ge/'
@response_file = 'response.html'
@json_file = 'data.json'
@db_config_path = 'config/database.yml'
@status_file_name = 'status.json'
@db_dump_file = 'real-estate.sql.gz'

# Tracks the number of ids pulled from ad lists to be scraped;
# @max_num_ids_to_scrape is compared to this to determine when to stop
@num_ids_scraped = 0

# Set this to limit the number of ids scraped (useful in test run)
# Note: Scraper likely will not stop precisely at this number
@max_num_ids_to_scrape = nil

# Set this to the page number where gathering ids should begin.
# Useful for starting a scrape from an old date in order to break up long
# scrape runs
@start_page_num = nil

@status = Status.new(@status_file_name)
@postings_database = PostingsDatabase.new(@db_config_path, @database_log)

@earliest_day_to_scrape = @postings_database.last_scraped_date
