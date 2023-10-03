module MockWS
    module Configuration
      def self.setup(force: false)
        if File.exist?(File.expand_path(MockWS::DEFAULT_CONFIG_PATH)) && !force
          puts 'MockWS already configured'
        else
          FileUtils.rm_rf File.expand_path(MockWS::DEFAULT_PATH)
          config_file = search_file_in_gem('mockws', 'config/mockws.yml')
          [ MockWS::DEFAULT_LOGS_PATH, MockWS::DEFAULT_CONFIG_PATH].each do |path|
            FileUtils.mkdir_p File.expand_path(path)
          end
          File.open(File.expand_path("#{MockWS::DEFAULT_LOGS_PATH}/#{MockWS::DEFAULT_LOG_FILENAME}"), 'w') { |file| file.write("# MockWS : beginning of log file\n") }
          FileUtils.cp config_file, File.expand_path(MockWS::DEFAULT_CONFIG_PATH)
          puts '[OK] Building config folder and initialize settings'
        end
      end
  
    

  
      class Checker
  
        extend Carioca::Injector
        inject service: :output
        inject service: :finisher
         
        def self.sanitycheck
          global_status = []
          output.info "Checking path for #{Etc.getpwuid(Process.uid).name} : "
          status = { true => :ok, false => :error }
          [DEFAULT_PATH,DEFAULT_CONFIG_PATH,DEFAULT_LOGS_PATH].each do |path|
            res = status[File::exist?(File::expand_path(path))]
            output.send res, path
            global_status.push res
          end
          output.info "Checking file for #{Etc.getpwuid(Process.uid).name} : "
  
          ["#{DEFAULT_CONFIG_PATH}/#{DEFAULT_SETTINGS_FILENAME}","#{DEFAULT_LOGS_PATH}/#{DEFAULT_LOG_FILENAME}"].each do |file|
            res = status[File::exist?(File::expand_path(file))]
            output.send res, file
            global_status.push res

          end
          finisher.secure_raise error_case: :sanitycheck_error, 
                                message: "MocKWS configuration error for #{Etc.getpwuid(Process.uid).name}" if global_status.include? :error
          

        end
      end
  
  
    end
  end