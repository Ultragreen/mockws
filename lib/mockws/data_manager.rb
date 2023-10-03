module MockWS
    class DataManager

        extend Carioca::Injector
        inject service: :configuration

        DEFAULT_OUTPUT_TYPE = :json
        @@default_output_type  = (configuration.settings.output.type)?  configuration.settings.output.type : DEFAULT_OUTPUT_TYPE
        TYPE_MAP = { json: "application/json", csv: "application/csv", yaml: "application/x-yaml" }


        def default_output_type
            return @@default_output_type
        end

        def self.from_csv(file)
            return CSV.read file 
        end


        def self.from_json(file)
            return JSON.load file
        end

        def self.from_yaml(file)
            return YAML.load_file file
        end


        def self.to_json(data)
            return data.to_json
        end

        def self.to_csv(data)
            return data.to_csv
        end

        def self.to_yaml(data)
            return data.to_yaml
        end


    end
end