module MockWS
    module CLI
        # The CLI Command structure for Thor
        class MainCommand < Thor
            
            
            class_option :debug, :desc => "Set log level to :debug", :aliases => "-d", :type => :boolean

            def initialize(*args) 
                super
                @output = Carioca::Registry.get.get_service name: :output
                @finisher = Carioca::Registry.get.get_service name: :finisher
                if options[:debug] then 
                    @output.level = :debug
                    @output.debug  "DEBUG activated" 
                end
            end
            
            # callback for managing ARGV errors
            def self.exit_on_failure?
                true
            end     

            # Thor method : starting MockWS daemon
            long_desc <<-LONGDESC
            Starting MockWS Daemon\n
            LONGDESC
            option :foreground, :type => :boolean,  :aliases => "-F"
            desc 'start', 'start the MockWS service' 
            def start
                @finisher.secure_execute! exit_case: :success_exit do
                    MockWS::Daemon::Controller::start options
                end
            end

             # Thor method : running of Appifier sanitycheck
            desc 'sanitycheck', 'Verify installation of MockWS for user'
            def sanitycheck 
                @finisher.secure_execute! exit_case: :sanitycheck_success do
                    MockWS::Configuration::Checker.sanitycheck
                end
                
            end


            # Thor method : stopping MockWS daemon
            long_desc <<-LONGDESC
            Stopping MockWS Daemon\n
            LONGDESC
            option :quiet, :type => :boolean,  :aliases => "-q"
            desc 'stop', 'stop the MockWS service' 
            def stop
                @finisher.secure_execute! exit_case: :success_exit do
                    MockWS::Daemon::Controller::stop options
                end
            end

            # Thor method : status for MockWS daemon
            long_desc <<-LONGDESC
            Status for MockWS Daemon\n
            LONGDESC
            desc 'status', 'Status for the MockWS service' 
            def status
                @finisher.secure_execute! exit_case: :success_exit do
                    MockWS::Daemon::Controller::status options
                end
            end

        end
    end
end
