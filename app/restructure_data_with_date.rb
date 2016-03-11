def restructure_data_with_date_directory
  dirs = (data_files_not_in_date_directories('en') +
          data_files_not_in_date_directories('ka'))

  dirs.each do |path|
    add_date_directory_to_file_path(path)
  end
end

def add_date_directory_to_file_path(path)
  data_json_path = path + '/data.json'
  data_json_zip_path = path + '/data.json.zip'

  if File.exist?(data_json_path)
    date = get_date_from_json_file(data_json_path)
    new_dir = get_new_data_path_with_date_directory(path, date)

    move_file_to_new_dir(
      path,
      new_dir
    )

  elsif File.exist?(data_json_zip_path)
    uncompress_zip_contents_into_same_folder(data_json_zip_path)
    date = get_date_from_json_file(data_json_path)
    File.delete(data_json_path)

    new_dir = get_new_data_path_with_date_directory(path, date)

    move_file_to_new_dir(
      path,
      new_dir
    )

  end
end

def get_date_from_json_file(json_file_path)
  data_json = JSON.parse(File.read(json_file_path))
  data_json['date']
end

def uncompress_zip_contents_into_same_folder(zip_path)
  Zip::File.open(zip_path) do |zip_file|
    zip_file.each do |entry|
      entry.extract(File.dirname(zip_path) + '/' + entry.name)
    end
  end
end

def move_file_to_new_dir(file_path, new_dir)
  FileUtils.mkdir_p new_dir unless File.exist?(new_dir)

  FileUtils.mv(file_path, new_dir)
end

def get_new_data_path_with_date_directory(path, date)
  [
    path[0, path.length - 2],
    date,
    '/'
  ].join
end

def data_files_not_in_date_directories(dir_name)
  Dir.glob("#{@data_path}/**/#{dir_name}").select do |path|
    !string_contains_date(path)
  end
end

def string_contains_date(str)
  (str =~ /\d{4}-\d{2}-\d{2}/).nil? ? false : true
end
