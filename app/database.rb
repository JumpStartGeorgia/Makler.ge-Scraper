#!/usr/bin/env ruby
# encoding: utf-8

####################################################
# to load the jobs to a database, please have the following:
# - database.yml file with the following keys and the appropriate values
# - the user must have the ability to create database and tables
# - this database.yml file is not saved into the git repository so
#   passwords are not shared with the world
# - yml keys:
#     database:
#     username:
#     password:
#     encoding: utf8
#     host: localhost
#     port: 3306
#     reconnect: true

# - you will need to create the database
# - the tables will be created if they do not exist
####################################################

require 'mysql2'
require 'yaml'
require 'logger'
require 'json'
require 'erb'


require_relative 'utilities'

class PostingsDatabase
  def initialize(db_config_path)
    # make sure the file exists
    unless File.exists?(db_config_path)
      log.error "The #{db_config_path} does not exist"
      exit
    end

    @db_config = YAML.load(ERB.new(File.read(db_config_path)).result)

    @mysql = Mysql2::Client.new(:host => db_config["host"], :port => db_config["port"], :database => db_config["database"],
                                :username => db_config["username"], :password => db_config["password"],
                                :encoding => db_config["encoding"], :reconnect => db_config["reconnect"])
  end

  attr_reader :db_config, :mysql

  def query(sql)
    @mysql.query(sql)
  end

  def dump(log, db_dump_file)
    log.info '------------------------------'
    log.info 'dumping database'
    log.info '------------------------------'

    Subexec.run "mysqldump --single-transaction -u'#{db_config["username"]}' -p'#{db_config["password"]}' #{db_config["database"]} | gzip > \"#{db_dump_file}\" "
  end

  def number_postings_by_date
    output_query_result_to_console(
      query('SELECT date, COUNT(id) FROM postings GROUP BY date;')
    )
  end

  def close
    mysql.close if mysql
  end

  private

  def output_query_result_to_console(query_result)
    query_result.each do |row|
      puts row
    end
  end
end

def update_database
  puts 'updating database'
  source = 'makler.ge'

  start = Time.now

  # log file to record messages
  # delete existing log file
  #File.delete('hr.gov.ge.log') if File.exists?('hr.gov.ge.log')
  log = create_log('Database Log', 'database.log')

  log.info "**********************************************"
  log.info "**********************************************"

  begin
    postings_database = PostingsDatabase.new(@db_config_path)

    ####################################################
    # if tables do not exist, create them
    ####################################################
    sql = "CREATE TABLE IF NOT EXISTS `postings` (\
          `id` int(11) NOT NULL AUTO_INCREMENT,\
          `posting_id` varchar(255) not null,\
          `locale` varchar(10) not null,\
          `source` varchar(255) not null,\
          `type` varchar(255) default null,\
          `property_type` varchar(255) default null,\
          `date` date not null,\
          `additional_info` text default null,\
          `daily_rent` varchar(255) default null,\
          `for_rent` varchar(255) default null,\
          `for_sale` varchar(255) default null,\
          `for_lease` varchar(255) default null,\
          `est_lease_price` varchar(255) default null,\
          `rent_price` numeric(15,2) default null,\
          `rent_price_currency` varchar(10) default null,\
          `rent_price_sq_meter` numeric(15,2) default null,\
          `rent_price_dollars` numeric(15,2) default null,\
          `rent_price_sq_meter_dollars` numeric(15,2) default null,\
          `rent_price_exchange_rate_to_dollars` numeric(15,5) default null,\
          `sale_price` numeric(15,2) default null,\
          `sale_price_currency` varchar(10) default null,\
          `sale_price_sq_meter` numeric(15,2) default null,\
          `sale_price_dollars` numeric(15,2) default null,\
          `sale_price_sq_meter_dollars` numeric(15,2) default null,\
          `sale_price_exchange_rate_to_dollars` numeric(15,5) default null,\
          `space` numeric(15,2) default null,\
          `space_measurement` varchar(20) default null,\
          `land` numeric(15,2) default null,\
          `land_measurement` varchar(20) default null,\
          `renovation` varchar(255) default null,\
          `view` varchar(255) default null,\
          `metro` varchar(255) default null,\
          `project` varchar(255) default null,\
          `place_condition` varchar(255) default null,\
          `function` varchar(255) default null,\
          `address` varchar(1000) default null,\
          `address_city` varchar(255) default null,\
          `address_area` varchar(255) default null,\
          `address_district` varchar(255) default null,\
          `address_street` varchar(255) default null,\
          `address_number` varchar(255) default null,\
          `phone` varchar(255) default null,\
          `cadastral` varchar(255) default null,\
          `all_floors` numeric(8,2) default null,\
          `floor` numeric(8,2) default null,\
          `rooms` numeric(8,2) default null,\
          `bedrooms` numeric(8,2) default null,\
          `conference_room` numeric(8,2) default null,\
          `suites` numeric(8,2) default null,\
          `wc` numeric(8,2) default null,\
          `bathroom` numeric(8,2) default null,\
          `shower` numeric(8,2) default null,\
          `fireplace` numeric(8,2) default null,\
          `air_conditioner` numeric(8,2) default null,\
          `balcony` numeric(8,2) default null,\
          `veranda` numeric(8,2) default null,\
          `loft` numeric(8,2) default null,\
          `bodrum` numeric(8,2) default null,\
          `mansard` numeric(8,2) default null,\
          `parking` numeric(8,2) default null,\
          `garage` numeric(8,2) default null,\
          `dist_from_tbilisi` numeric(8,2) default null,\
          `dist_from_cent_street` numeric(8,2) default null,\
          `box` numeric(8,2) default null,\
          `buildings` numeric(8,2) default null,\
          `administration_building` numeric(8,2) default null,\
          `workroom` numeric(8,2) default null,\
          `stockroom` numeric(8,2) default null,\
          `coefficient_k1` numeric(8,2) default null,\
          `coefficient_k2` numeric(8,2) default null,\
          `created_at` datetime,\
          PRIMARY KEY `Index 1` (`id`),\
          KEY `Index 2` (`posting_id`),\
          KEY `Index 3` (`locale`),\
          KEY `Index 4` (`source`),\
          KEY `Index 5` (`type`),\
          KEY `Index 6` (`property_type`),\
          KEY `Index 7` (`rent_price_dollars`),\
          KEY `Index 8` (`rent_price_sq_meter_dollars`),\
          KEY `Index 9` (`sale_price_dollars`),\
          KEY `Index 10` (`sale_price_sq_meter_dollars`),\
          KEY `Index 11` (`space`),\
          KEY `Index 12` (`land`),\
          KEY `Index 13` (`address_city`),\
          KEY `Index 14` (`address_area`),\
          KEY `Index 15` (`address_district`),\
          KEY `Index 16` (`address_street`),\
          CONSTRAINT uc_id_locale UNIQUE (posting_id, locale)\
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    postings_database.query(sql)


    ####################################################
    # load the data
    ####################################################
    files_processed = 0
    length = @data_path.split('/').length

    empty_status_processed_ids

    @locales.keys.each do |locale_key|
      locale = locale_key.to_s
      # if there are any ids for this locale, procss them
      if @status['ids_to_process']['db'][locale].length > 0
        ids = @status['ids_to_process']['db'][locale].dup
        ids.each do |id|
          parent_id = get_parent_id_folder(id)
          file_path = @data_path + parent_id + "/" + id + "/" + locale + "/" + @json_file
          if File.exists?(file_path)
            # pull in json
            json = JSON.parse(File.read(file_path))
            compress_file(file_path)

            # delete the record if it already exists
            sql = delete_record_sql(postings_database.mysql, id, locale)
            postings_database.query(sql)

            # create sql statement
            sql = create_sql_insert(postings_database.mysql, json, source, locale)
            if !sql.nil?
              # create record
              postings_database.query(sql)

              # remove the id from the status list to indicate it was processed
              remove_status_db_id(id, locale)

              add_status_processed_id(id)

              files_processed += 1
              @statistics_sheet.increase_num_db_records_saved_by_1

              ad_date = Date.strptime(json['date'], '%Y-%m-%d')
              @statistics_sheet.update_saved_records_date_range(ad_date)

              if files_processed % 100 == 0
                puts "#{files_processed} json files processed so far"
              end
            end
          end
        end
      end
    end

    log.info "------------------------------"
    log.info "It took #{Time.now - start} seconds to load #{files_processed} json files into the database"
    log.info "------------------------------"

    postings_database.dump(log, @db_dump_file)

  rescue Mysql2::Error => e
    log.info "+++++++++++++++++++++++++++++++++"
    log.error "Mysql error ##{e.errno}: #{e.error}"
    log.info "+++++++++++++++++++++++++++++++++"
  ensure
    postings_database.close unless postings_database.nil?
  end
end
