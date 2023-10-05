module MockWS
    class RouteManager
        
        extend Carioca::Injector
        inject service: :output
        inject service: :configuration

        DEFAULT_STATUS = 200
        
        def self.get_response_time(value)
            return {value: value[:response_time], type: :static} if value.include? :response_time
            return {value: rand(1..value[:random_time]), type: :random} if value.include? :random_time
            return {value: 0, type: :instant} 
        end


        def self.configure(service)
            @service = service
            output.info "Mock routes initialisation : "
            configuration.settings.services.select {|key,value| [:static,:inline].include? value[:type]}.each do |_key, definition|
                create_route(definition)    
            end
        end

        # build a session number
        # @return [String] Session number
        def self.get_session
            return "#{Time.now.to_i.to_s}#{rand(999)}"
        end
  

        private


        def self.create_route(definition)
            output.item "Adding #{definition[:type]} route #{definition[:route]} on verb #{definition[:verb]}"
            unless self.respond_to? "#{definition[:type]}_content".to_sym, true then
                output.error 'type not defined or type not recognize'
                return false
            end
            @service.send(definition[:verb], definition[:route]) do
                session = MockWS::RouteManager::get_session
                output.debug "[#{session}] Executing route #{definition[:route]} on verb #{definition[:verb]}"
                response_time = MockWS::RouteManager::get_response_time definition
                output.debug "[#{session}] Response time #{response_time[:type]} value #{response_time[:value]}" unless response_time[:type] == :instant
                sleep(response_time[:value]) if response_time[:value]
                return_status = (definition[:status])? definition[:status] : DEFAULT_STATUS
                output.debug "[#{session}] status : #{return_status}"
                status return_status
                data = MockWS::RouteManager.send "#{definition[:type]}_content".to_sym, definition
                if definition.include? :to then
                    raise "Output type not supported" unless MockWS::DataManager::TYPE_MAP.keys.include? definition[:to]
                    return MockWS::DataManager.send "to_#{definition[:to]}", data
                else
                    return MockWS::DataManager.send "to_#{MockWS::DataManager.default_output_type}", data
                end
            end
        end

        def self.static_content(definition)
            ext = File.extname(definition[:path])[1..-1].to_sym   
            return MockWS::DataManager.send "from_#{ext}", definition[:path]
        end


        def self.inline_content(definition)
            return definition[:data]
        end


    end
end
