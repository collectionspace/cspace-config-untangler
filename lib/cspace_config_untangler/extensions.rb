# frozen_string_literal: true

module CspaceConfigUntangler
  class Extension
    attr_reader :name
    attr_reader :profile
    attr_reader :config
    attr_reader :type
    attr_reader :rectypes

    def initialize(profileobj, extname)
      @name = extname
      @profile = profileobj
      @config = @profile.config["extensions"][@name]
      determine_types
    end

    private

    def determine_types
      case @name
      when "contact"
        @type = "subrecord"
        @rectypes = @profile.config["recordTypes"].keys.select { |rt|
          @profile.config["recordTypes"][rt].dig("subrecords", "contact")
        }
      when "blob"
        @type = "subrecord"
        @rectypes = @profile.config["recordTypes"].keys.select { |rt|
          @profile.config["recordTypes"][rt].dig("subrecords", "blob")
        }
      else
        chk = @config.keys & @profile.rectypes.map { |rt| rt.name }

        @type = case chk.length
        when 0
          "generic"
        else
          "rectype specific"
        end

        @rectypes = chk
      end
    end
  end
end
