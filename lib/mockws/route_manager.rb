module MockWS
    class RouteManager
        
        extend Carioca::Injector
        inject service: :output
        inject service: :configuration
        
        def get_response_time(value)
            return  value[:response_time]if value.include? :response_time
            return  Random::new.rand(value[:random_time]) if value.include? :random_time
            return 0
        end


        def initialize(service)
            @service = service
            output.info "Mock routes initialisation : "
            configuration.settings.services.each do |_key, definition|
                create_proc_route(definition)    
            end
        end

        private


        def create_proc_route(definition)
            output.item "Adding #{definition[:type]} route #{definition[:route]} on verb #{definition[:verb]}"
            unless self.respond_to? "#{definition[:type]}_content".to_sym, true then
                output.error 'type not defined or type not recognize'
                return false
            end
            response_time = get_response_time definition
            @service.send(definition[:verb], definition[:route]) do
                
                sleep(response_time) if response_time
                status definition[:status]
                return self.send "#{definition[:type]}_content".to_sym, definition
            end
        end

        def static_content(definition)
            ext = File.extname(definition[:path])[1..-1].to_sym
            data = File.readlines(definition[:path]).join('\n')    
            content_type = configuration.settings.type_map[ext]  
            return data
        end


        def inline_content(definition)
            content_type =  configuration.settings.type_map[value[:to]]
            return definition[:data].send(configuration.settings.serializer[definition[:to]])
        end


    end
end
