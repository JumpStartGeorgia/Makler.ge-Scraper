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

    @status.reset_last_id_processed

    @locales.keys.each do |locale_key|
      # if there are any ids for this locale, procss them
      next unless @status.db_ids_for_locale?(locale_key)

      ids = @status.db_ids_to_process[locale_key].dup

      ids.each do |id|
        parent_id = get_parent_id_folder(id)
        file_path = "#{@data_path}#{parent_id}/#{id}/#{locale_key}/#{@json_file}"

        next unless File.exist?(file_path)

        # pull in json
        json = JSON.parse(File.read(file_path))
        compress_file(file_path)

        # delete the record if it already exists
        sql = delete_record_sql(postings_database.mysql, id, locale_key.to_s)
        postings_database.query(sql)

        # create sql statement
        sql = create_sql_insert(postings_database.mysql, json, source, locale_key.to_s)

        next if sql.nil?

        # create record
        postings_database.query(sql)

        @status.remove_db_id(id, locale_key)

        @status.add_processed_id(id)

        files_processed += 1
        @statistics_sheet.increase_num_db_records_saved_by_1

        ad_date = Date.strptime(json['date'], '%Y-%m-%d')
        @statistics_sheet.update_saved_records_date_range(ad_date)

        if files_processed % 100 == 0
          puts "#{files_processed} json files processed so far"
        end
      end
    end

    postings_database.log.info '------------------------------'
    postings_database.log.info "It took #{Time.now - start} seconds to load #{files_processed} json files into the database"
    postings_database.log.info '------------------------------'

    postings_database.dump(@db_dump_file)

  rescue Mysql2::Error => e
    postings_database.log.error "Mysql error ##{e.errno}: #{e.error}"
  ensure
    postings_database.close unless postings_database.nil?
  end
end
