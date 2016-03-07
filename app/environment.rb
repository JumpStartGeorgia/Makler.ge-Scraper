require 'dotenv'
Dotenv.load

require 'mysql2'
require 'yaml'
require 'logger'
require 'erb'
require 'pry-byebug'
require 'typhoeus'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'logger'
require 'fileutils'
require 'mail'
require 'subexec'
require 'zip'

require_relative 'utilities'
require_relative 'database'
require_relative 'scraper_report'
require_relative 'custom_logger'
require_relative 'makler'
require_relative 'postings_database'
require_relative 'statistics_sheet'
require_relative 'error_sheet'
require_relative '../config/mail_config'

@data_files_log = create_log('Data Files Log', 'data_files.log')
@missing_param_log = create_log('Makler Missing Params Log', 'makler_missing_params.log')
@log = create_log('Makler Log', 'makler.log')

@log.info "**********************************************"
@log.info "**********************************************"

# starting url
@posting_url = "http://makler.ge/?pg=ann&id="
@serach_url = "http://makler.ge/?pg=search&cat=-1&tp=-1&city_id=-1&raion_id=0&price_f=&price_t=&valuta=2&sart_f=&sart_t=&rooms_f=&rooms_t=&ubani_id=0&street_id=0&parti_f=&parti_t=&mdgomareoba=0&remont=0&project=0&xedi=0&metro_id=0&is_detailed_search=2&sb=d"
@page_param = "&p="
@lang_param = "&lan="

# track processing status
@status = get_status
@found_all_ids = false


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

@statistics_sheet = StatisticsSheet.new
@error_sheet = ErrorSheet.new

@data_path = 'data/makler.ge/'
@response_file = 'response.html'
@json_file = 'data.json'
@db_config_path = 'config/database.yml'
@status_file = 'status.json'
@db_dump_file = 'real-estate.sql.gz'

# Tracks the number of ids pulled from ad lists to be scraped;
# @max_num_ids_to_scrape is compared to this to determine when to stop
@num_ids_to_scrape = 0

# Set this to limit the number of ids scraped (useful in test run)
# Note: Scraper likely will not stop precisely at this number
@max_num_ids_to_scrape = nil

# Set this to the page number where gathering ids should begin.
# Useful for starting a scrape from an old date in order to break up long
# scrape runs
@start_page_num = nil

# which languages to process
# georgian
@locales = {}
@locales[:ka] = {}
@locales[:ka][:locale] = 'geo'
@locales[:ka][:id] = '1'
@locales[:ka][:types] = {}
@locales[:ka][:types][:sale] = 'იყიდება'
@locales[:ka][:types][:rent] = 'ქირავდება'
@locales[:ka][:types][:lease] = 'გირავდება'
@locales[:ka][:types][:daily_rent] = 'დღიური გაქ.'
@locales[:ka][:property_types] = {}
@locales[:ka][:property_types][:apartment] = 'ბინა'
@locales[:ka][:property_types][:private_house] = 'საკუთარი სახლი'
@locales[:ka][:property_types][:office] = 'ოფისი'
@locales[:ka][:property_types][:commerical_space] = 'კომერციული ფართი'
@locales[:ka][:property_types][:country_house] = 'აგარაკი'
@locales[:ka][:property_types][:land] = 'მიწა'
@locales[:ka][:keys] = {}
@locales[:ka][:keys][:details] = {}
@locales[:ka][:keys][:details][:daily_rent] = 'დღიური გაქ.'
@locales[:ka][:keys][:details][:for_sale] = 'იყიდება'
@locales[:ka][:keys][:details][:for_rent] = 'ქირავდება'
@locales[:ka][:keys][:details][:for_lease] = 'გირავდება'
@locales[:ka][:keys][:details][:est_lease_price] = 'სავარ. გაქ. ფასი'
@locales[:ka][:keys][:details][:space] = 'ფართობი'
@locales[:ka][:keys][:details][:land] = 'მიწა'
@locales[:ka][:keys][:details][:renovation] = 'რემონტი'
@locales[:ka][:keys][:details][:view] = 'ხედი'
@locales[:ka][:keys][:details][:metro] = 'მეტრო'
@locales[:ka][:keys][:details][:project] = 'პროექტი'
@locales[:ka][:keys][:details][:condition] = 'მდგომარეობა'
@locales[:ka][:keys][:details][:function] = 'დანიშნულება'
@locales[:ka][:keys][:details][:address] = 'მისამართი'
@locales[:ka][:keys][:details][:phone] = 'ტელეფონი'
@locales[:ka][:keys][:details][:cadastral] = 'საკადასტრო'
@locales[:ka][:keys][:specs] = {}
@locales[:ka][:keys][:specs][:all_floors] = 'სართული სულ:'
@locales[:ka][:keys][:specs][:floor] = 'სართული:'
@locales[:ka][:keys][:specs][:rooms] = 'ოთახები:'
@locales[:ka][:keys][:specs][:bedrooms] = 'საძინებელი:'
@locales[:ka][:keys][:specs][:conference_room] = 'საკონფერენციო:'
@locales[:ka][:keys][:specs][:suites] = 'ლუქსი:'
@locales[:ka][:keys][:specs][:wc] = 'სველი წერტილი:'
@locales[:ka][:keys][:specs][:bathroom] = 'აბაზანა:'
@locales[:ka][:keys][:specs][:shower] = 'საშხაპე:'
@locales[:ka][:keys][:specs][:fireplace] = 'ბუხარი:'
@locales[:ka][:keys][:specs][:air_conditioner] = 'კონდიციონერი:'
@locales[:ka][:keys][:specs][:balcony] = 'აივანი:'
@locales[:ka][:keys][:specs][:veranda] = 'ვერანდა (m²):'
@locales[:ka][:keys][:specs][:loft] = 'სხვენი (m²):'
@locales[:ka][:keys][:specs][:bodrum] = 'სარდაფი (m²):'
@locales[:ka][:keys][:specs][:mansard] = 'მანსარდა (m²):'
@locales[:ka][:keys][:specs][:parking] = 'პარკინგი:'
@locales[:ka][:keys][:specs][:garage] = 'ავტოფარეხი:'
@locales[:ka][:keys][:specs][:dist_from_tbilisi]= 'დაშორება თბილისიდან:'
@locales[:ka][:keys][:specs][:dist_from_cent_street] = 'დაშორება ცენტ. გზიდან:'
@locales[:ka][:keys][:specs][:box] = 'ბოქსი:'
@locales[:ka][:keys][:specs][:buildings] = 'შენობა-ნაგებობა:'
@locales[:ka][:keys][:specs][:administration_building] = 'ადმინისტ. შენობა (m²):'
@locales[:ka][:keys][:specs][:workroom] = 'საწარმოო შენობა (m²):'
@locales[:ka][:keys][:specs][:stockroom] = 'სასაწყობე ფართი (m²):'
@locales[:ka][:keys][:specs][:coefficient_k1] = 'კოეფიციენტი k1:'
@locales[:ka][:keys][:specs][:coefficient_k2] = 'კოეფიციენტი k2:'
@locales[:ka][:keys][:additional_info]  = 'დამატებითი ინფორმაცია'

# english
@locales[:en] = {}
@locales[:en][:locale] = 'eng'
@locales[:en][:id] = '2'
@locales[:en][:types] = {}
@locales[:en][:types][:sale] = 'for sale'
@locales[:en][:types][:rent] = 'for rent'
@locales[:en][:types][:lease] = 'for lease'
@locales[:en][:types][:daily_rent] = 'daily rent'
@locales[:en][:property_types] = {}
@locales[:en][:property_types][:apartment] = 'apartment'
@locales[:en][:property_types][:private_house] = 'private house'
@locales[:en][:property_types][:office] = 'office'
@locales[:en][:property_types][:commerical_space] = 'commercial space'
@locales[:en][:property_types][:country_house] = 'country house'
@locales[:en][:property_types][:land] = 'land'
@locales[:en][:keys] = {}
@locales[:en][:keys][:details] = {}
@locales[:en][:keys][:details][:daily_rent] = 'daily rent'
@locales[:en][:keys][:details][:for_sale] = 'for sale'
@locales[:en][:keys][:details][:for_rent] = 'for rent'
@locales[:en][:keys][:details][:for_lease] = 'for lease'
@locales[:en][:keys][:details][:est_lease_price] = 'est. lease price'
@locales[:en][:keys][:details][:space] = 'space'
@locales[:en][:keys][:details][:land] = 'land'
@locales[:en][:keys][:details][:renovation] = 'renovation'
@locales[:en][:keys][:details][:view] = 'view'
@locales[:en][:keys][:details][:metro] = 'subway'
@locales[:en][:keys][:details][:project] = 'project'
@locales[:en][:keys][:details][:condition] = 'condition'
@locales[:en][:keys][:details][:function] = 'function'
@locales[:en][:keys][:details][:address] = 'address'
@locales[:en][:keys][:details][:phone] = 'phone'
@locales[:en][:keys][:details][:cadastral] = 'cadastral'
@locales[:en][:keys][:specs] = {}
@locales[:en][:keys][:specs][:all_floors] = 'all floors:'
@locales[:en][:keys][:specs][:floor] = 'floor:'
@locales[:en][:keys][:specs][:rooms] = 'room(s):'
@locales[:en][:keys][:specs][:bedrooms] = 'bedroom(s):'
@locales[:en][:keys][:specs][:conference_room] = 'conference room:'
@locales[:en][:keys][:specs][:suites] = 'suites:'
@locales[:en][:keys][:specs][:wc] = 'wc:'
@locales[:en][:keys][:specs][:bathroom] = 'bathroom:'
@locales[:en][:keys][:specs][:shower] = 'shower:'
@locales[:en][:keys][:specs][:fireplace] = 'fireplace:'
@locales[:en][:keys][:specs][:air_conditioner] = 'air-conditioner:'
@locales[:en][:keys][:specs][:balcony] = 'balcony:'
@locales[:en][:keys][:specs][:veranda] = 'veranda (m²):'
@locales[:en][:keys][:specs][:loft] = 'loft (m²):'
@locales[:en][:keys][:specs][:bodrum] = 'bodrum (m²):'
@locales[:en][:keys][:specs][:mansard] = 'mansard (m²):'
@locales[:en][:keys][:specs][:parking] = 'parking:'
@locales[:en][:keys][:specs][:garage] = 'garage:'
@locales[:en][:keys][:specs][:dist_from_tbilisi]= 'distance from tbilisi:'
@locales[:en][:keys][:specs][:dist_from_cent_street] = 'distance from cent. street:'
@locales[:en][:keys][:specs][:box] = 'box:'
@locales[:en][:keys][:specs][:buildings] = 'buildings:'
@locales[:en][:keys][:specs][:administration_building] = 'administ. building (m²):'
@locales[:en][:keys][:specs][:workroom] = 'workroom (m²):'
@locales[:en][:keys][:specs][:stockroom] = 'stockroom (m²):'
@locales[:en][:keys][:specs][:coefficient_k1] = 'coefficient k1:'
@locales[:en][:keys][:specs][:coefficient_k2] = 'coefficient k2:'
@locales[:en][:keys][:additional_info]  = 'additional information'
