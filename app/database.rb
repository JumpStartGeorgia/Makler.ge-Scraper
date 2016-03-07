require_relative 'environment'

def update_database
  puts 'updating database'
  source = 'makler.ge'

  start = Time.now

  begin
    postings_database = PostingsDatabase.new(@db_config_path, @database_log)

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

    postings_database.dump(@db_dump_file)

  rescue Mysql2::Error => e
    postings_database.log.error "Mysql error ##{e.errno}: #{e.error}"
  ensure
    postings_database.close unless postings_database.nil?
  end
end
