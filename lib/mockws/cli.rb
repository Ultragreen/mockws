module MockWS
    module CLI
        # The CLI Command structure for Thor
        class MainCommand < Thor
            
            
            def initialize(*args)
                super
                @output = Carioca::Registry.get.get_service name: :output
                @finisher = Carioca::Registry.get.get_service name: :finisher
            end
            
            # callback for managing ARGV errors
            def self.exit_on_failure?
                true
            end
            
            desc 'start', 'start the MockWS service' 
            def start
                MockWS::Service::init
                MockWS::Service.run!
            end
        end
    end
end
