module MockWS
    
    module Daemon
        class Controller
            
            DAEMON_NAME =  "MockWS : Daemon"
            MOCKWS_PATH = File::expand_path("~/.mockws")
            PID_FILE = MOCKWS_PATH + "/mockws.pid"
            STDOUT_TRACE = MOCKWS_PATH + "/stdout.trace"
            STDERR_TRACE = MOCKWS_PATH + "/stderr.trace"

            extend Carioca::Injector
            inject service: :configuration
            inject service: :output
            inject service: :finisher
            inject service: :toolbox

            def self.start options
                output.level = :fatal if options[:quiet]
                realpid = toolbox.get_processes pattern: DAEMON_NAME
                
                unless File::exist? PID_FILE then
                    unless realpid.empty? then
                        finisher.secure_raise error_case: :already_exist, message: "MockWS Process already launched "
                    end
                    
                    daemon_config = {:description => DAEMON_NAME,
                        :pid_file => PID_FILE,
                        :stdout_trace => STDOUT_TRACE,
                        :stderr_trace => STDERR_TRACE,
                        :foreground => options[:foreground]
                    }
                    
                    ["int","term","hup"].each do |type| daemon_config["sig#{type}_handler".to_sym] = Proc::new {  MockWS::Service.quit! } end
                        res = daemonize daemon_config do
                            output.info "Starting MockWS Daemon"
                            MockWS::Service::init
                            MockWS::Service.run!
                        end
                        sleep 1
                        if res == 0 then
                            pid = `cat #{PID_FILE}`.to_i
                            output.ok "MockWS Started, with PID : #{pid}"
                            output.ok "MockWS successfully loaded."
                        else
                            finisher.secure_raise error_case: :unknown_error, message: "MockWS loading error, see logs for more details."
                        end
                        
                    else
                        finisher.secure_raise error_case: :already_exist, message: "Pid File, please verify if MockWS is running."
                    end
                end

                # Stop MockWS daemon
                # @param [Hash] options
                # @option options [Symbol] :quiet activate quiet mode for log (limit to :fatal)
                def self.stop(options = {})
                    output.level = :fatal if options[:quiet]
                    if File.exist?(PID_FILE) then
                        begin
                            pid = `cat #{PID_FILE}`.to_i
                            Process.kill("TERM", pid)
                            output.ok 'Splash WebAdmin stopped succesfully'
                        rescue Errno::ESRCH

                            finisher.secure_raise error_case: :not_found, message: "Process of PID : #{pid} not found, erasing Pidfile "
                        ensure 
                            FileUtils::rm PID_FILE if File::exist? PID_FILE
                        end
                        return "MockWS stopped"
                    else
                        finisher.secure_raise error_case: :not_found, message: "Splash WebAdmin is not running"
                    end
                end

                # Status of the Splash WebAdmin, display status
                # @param [Hash] options ignored
                # @return [Hash] Exiter Case (:status_ko, :status_ok)
                def self.status(options = {})
                    pid = realpid = ''
                    pid = `cat #{PID_FILE}`.to_s if File.exist?(PID_FILE)
                    listpid = toolbox.get_processes pattern: DAEMON_NAME
                    pid.chomp!
                    if listpid.empty? then
                        realpid = ''
                    else
                        realpid = listpid.first
                    end
                    unless realpid.empty? then
                        output.item "MockWS daemon process is running with PID #{realpid} "
                    else
                        output.item 'MockWS daemon not found '
                    end
                    unless pid.empty? then
                        output.item "and PID file exist with PID #{pid}"
                    else
                        output.item "and PID file don't exist"
                    end
                    if pid == realpid then
                        return "MockWS status clean"
                    elsif pid.empty? then
                        finisher.secure_raise error_case: :status_ko, message: "PID File error, you have to kill process manualy, with : '(sudo )kill -TERM #{realpid}'"
                    elsif realpid.empty? then
                        finisher.secure_raise error_case: :status_ko, message: "Process MockWS daemon missing, run 'mockws stop' before reload properly"
                    end
                end
                
            end
        end
    end
    
