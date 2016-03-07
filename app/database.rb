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
require_relative 'postings_database'

def update_database
  puts 'updating database'
  source = 'makler.ge'

  start = Time.now

  log = create_log('Database Log', 'database.log')

  begin
    postings_database = PostingsDatabase.new(@db_config_path, log)

    postings_database.log.info '**********************************************'
    postings_database.log.info '**********************************************'

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

    postings_database.log.info "------------------------------"
    postings_database.log.info "It took #{Time.now - start} seconds to load #{files_processed} json files into the database"
    postings_database.log.info "------------------------------"

    postings_database.dump(log, @db_dump_file)

  rescue Mysql2::Error => e
    postings_database.log.error "Mysql error ##{e.errno}: #{e.error}"
  ensure
    postings_database.close unless postings_database.nil?
  end
end
