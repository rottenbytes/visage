module Visage
  class Config 

    class << self
      def use
        @configuration ||= {}
        yield @configuration
        nil
      end

      def method_missing(method, *args)
        if method.to_s[-1,1] == '='
          @configuration[method.to_s.tr('=','')] = *args
        else
          @configuration[method.to_s]
        end
      end

      def get(profilename)
        if @configuration.has_key? profilename then
            @configuration[profilename]
        else
            @configuration["profiles"]
        end
      end

      def to_hash
        @configuration
      end
    end

    class Profiles
      class << self
        require 'ostruct'

        attr_accessor :profiles

        def get(id)
          id.gsub!(/\s+/, '+')
          if found = @profiles.find {|p| p[1]["splat"] == id }
            OpenStruct.new(found[1])
          else
            nil
          end
        end

        def all
          # here be ugliness
          profiles = @profiles.to_a.sort_by { |profile| 
            profile[1]["order"] 
          }.map { |profile| 
            OpenStruct.new(profile[1].merge({'name' => profile[0]}))
          }
        end
      end
    end
    
    class Groups
        class << self
        
        attr_accessor :groups
        
        def all
            hosts_groups = Visage::Config.groups
            @groups = {}
            
            @hosts = CollectdJSON.hosts
            @hosts.each { |h|
                group = hosts_groups[h]
                if !@groups.has_key?(group) then
                    @groups[group]=[]
                end
                @groups[group].push h
                
            }
            
            @groups.delete nil
            @groups
        end
        end
    end
    
  end
end
