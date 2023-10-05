require 'ostruct'
require 'uuid'

module MockWS
    
    
    
    class Store
        
        TYPE_MAP = {
            :string => :to_s,
            :integer => :to_i,
            :other => :to_s 
            
        }
        def initialize( )
            @models = {}
            @definitions = {}
            @keys = {}
            
        end
        
        def models
            return @models.keys
        end

        def add_model(definition:)
            @models[definition[:object]] = []
            @definitions[definition[:object]] = definition[:model]
            @keys[definition[:object]] = definition[:primary_key]
        end
        
        def delete_model(name:)
            @models.delete(name)
        end
        
        def create(model:, data:)
            data[:id] = UUID.generate 
            status = check_record(model: model, data: data)
            @models[model].push data  if status[:status] == true
            return status
        end
        
        
        def retrieve(model:, key:)
            return @models[model].select{|value| value[@keys[model]] == key}.first
        end
        
        
        def update(model:, key:, data:)
            record = @models[model].select{|value| value[@keys[model]] == key}.first
            status = check_record(model: model, data: data, update: true)
            record.merge! data if status[:status] == true
            return status
        end
        
        
        def destroy(model:, key:)
            res = @models[model].reject!{|value| value[@keys[model]] == key}
            return (res.nil?)? false : true 
        end
        
        def list(model: )
            return @models[model]
        end
        
        def exist?(model:,  key:)
            return @models[model].index{|value| value[@keys[model]] == key} == 1 
        end
        
        private 
        def check_record(model:, data: , update: false)
            result = {status: true, unknowns: [],mandatories: [], unicity: []}
            result[:unknowns].concat check_unknown(model: model, data: data)
            result[:mandatories].concat check_mandatory(model: model, data: data) unless update
            result[:unicity].concat check_unicity(model: model, data: data)
            result[:status] = false if  (!result[:unknowns].empty? or !result[:mandatories].empty? or !result[:unicity].empty?)
            return result
        end
        
        def check_unknown(model:, data: )
            unknowns = []
            data.keys.each do |item|
                unknowns.push item unless @definitions[model].keys.include? item
            end
            unknowns.delete :id
            return unknowns
        end
        
        def check_mandatory(model:, data: )
            mandatories = []
            @definitions[model].select {|_key, value| value.dig(:mandatory) == true }.keys.each do |key| 
                mandatories.push key unless data.keys.include? key
            end
            return mandatories
        end
        
        def check_unicity(model:, data: )
            unicity = []
            data.each do |key,value|
                if @definitions[model].dig(key, :unicity) then  
                   unicity.push key unless @models[model].select {|item| item[key] == value   }.empty?
                end
            end
            return unicity
        end
        
        
    end
    
    
    
    
    
    
    class CRUDManager
        
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
            @@service = service
            unless configuration.settings.services.select {|key,value|  value[:type] == :crud }.empty? then
                @@store = MockWS::Store::new
                output.info "Mock CRUD initialisation : "
                configuration.settings.services.select {|key,value|  value[:type] == :crud }.each do |_key, definition|
                    @@store.add_model definition: definition
                    output.item "Create JSON CRUD for #{definition[:object]}"
                    output.arrow "GET /crud/#{definition[:object]}/list"
                    output.arrow "GET /crud/#{definition[:object]}/<KEY>"
                    output.arrow "POST /crud/#{definition[:object]} [JSON BODY]"
                    output.arrow "PUT /crud/#{definition[:object]} [JSON BODY]"
                    output.arrow "DELETE /crud/#{definition[:object]}/<KEY> "
                    
                end
                create_crud_service
            end
        end
        
        private
        
        def self.create_crud_service
            @@service.get  '/crud/:model/list' do |model|
                result = finisher.secure_api_return(return_case: :status_ok, structured: true, json: false) do
                    finisher.secure_raise message: "Error model #{model} not found !", error_case: :status_ko unless @@store.models.include? model
                    @@store.list(model: model)
                end
                status result[:code]
                JSON.pretty_generate(JSON.parse(result.to_json))
            end
            
            @@service.get  '/crud/:model/:item' do |model,item|
                result = finisher.secure_api_return(return_case: :status_ok, structured: true, json: false) do
                    finisher.secure_raise message: "Error model #{model} not found !", error_case: :status_ko unless @@store.models.include? model
                    res = @@store.retrieve(model: model, key: item)
                    finisher.secure_raise message: "No record found", error_case: :not_found if res.nil?
                    res
                end
                status result[:code]
                JSON.pretty_generate(JSON.parse(result.to_json))
            end
            
            @@service.put  '/crud/:model/:item' do |model,item|
                finisher.secure_api_return(return_case: :status_ok, structured: true, json: true) do
                    finisher.secure_raise message: "Error model #{model} not found !", error_case: :status_ko unless @@store.models.include? model



                end
            end
            
            @@service.post '/crud/:model' do |model|
                result = finisher.secure_api_return(return_case: :status_ok, structured: true, json: false) do
                    data = JSON.parse(request.body.read, symbolize_names: true)
                    finisher.secure_raise message: "Error model #{model} not found !", error_case: :status_ko unless @@store.models.include? model
                    res  = @@store.create model: model, data: data
                    code = res.delete(:status)
                    finisher.secure_raise message: "Creation Error : #{res} ", error_case: :status_ko unless code
                    res
                end
                status result[:code]
                JSON.pretty_generate(JSON.parse(result.to_json))
            end
            
            @@service.delete '/crud/:model/:item' do |model,item|
                result = finisher.secure_api_return(return_case: :status_ok, structured: true, json: false) do
                    finisher.secure_raise message: "Error model #{model} not found !", error_case: :status_ko unless @@store.models.include? model
                    if @@store.destroy(model: model, key: item) then
                      res = 'record successfully deleted'
                    else
                       finisher.secure_raise message: "Suppression failed : #{item} ", error_case: :status_ko unless @@store.destroy(model: model, key: item)
                    end
                    res
                end
                status result[:code]
                JSON.pretty_generate(JSON.parse(result.to_json))
            end
            
            
        end


    end
    
end





# store = MockWS::Store::new
# store.add_model definition:  {:type=>:crud, 
#                               :object=>"post", 
#                               :primary_key => :name,  
#                               :model=>{
#                                 :name => {:type => :string, :mandatory => true, :unicity => true},
#                                 :title=> {:type => :string, :mandatory => true, :unicity => false}, 
#                                 :description=> {:type => :string, :mandatory => false, :unicity => false}
#                               }
#                             }
# print "* create good post1 : " ;puts (store.create model: "post", data: {name: "post1", title: "mon titre", description: "bla blah"})? "created" : "error"
# print "* create good post2 : " ;puts (store.create model: "post", data: {name: "post2", title: "mon titre", description: "bla blah"})? "created" : "error"
# print "* create new post2 (duplicate): " ;puts (store.create model: "post", data: {name: "post2", title: "mon titre", description: "bla blah"})? "created" : "error"
# print "* create bad post3 (unknown key) : " ;puts (store.create model: "post", data: {name: "post3", title: "mon titre", description: "bla blah", toto: "test"})? "created" : "error"
# print "* create bad post5 (mandatory title) : " ;puts (store.create model: "post", data: {name: "post5",  description: "bla blah"})? "created" : "error"
# print "* list : " ;p store.list model: "post"
# print "* get post1 : " ; p store.retrieve model: "post", key: "post1"
# print "* update : " ;p store.update model: "post", key: "post2", data: {title: "toto"}
# print "* update (not a mandatory): " ;p store.update model: "post", key: "post2", data: {description: "desc 2"}
# print "* update bad (unknown key): " ;p store.update model: "post", key: "post2", data: {title: "toto", toto: "test"}
# print "* update bad (unicity): " ;p store.update model: "post", key: "post2", data: {title: "toto", name: "post1" }
# print "* update change name: " ;p store.update model: "post", key: "post2", data: { name: "post4" }
# print "* list : " ;p store.list model: "post"
# print "* exists post4 : " ;p store.exist? model: "post", key: "post4"
# print "* exists post3 : " ;p store.exist? model: "post", key: "post3"
# print "* delete post1 : " ;p store.destroy model: "post", key: "post1"
# print "* list : " ; p store.list model: "post"