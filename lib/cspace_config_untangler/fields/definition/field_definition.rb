# frozen_string_literal: true

require_relative "field_config_child"
require_relative "../value_sources/type_extractor"
require_relative "../../track_attributes"
require_relative "../../upgrade_warner"

module CspaceConfigUntangler
  module Fields
    module Definition
      class FieldDefinition < FieldConfigChild
        include CCU::TrackAttributes
        attr_reader :name, :ns, :ns_for_id, :id,
          :schema_path,
          :repeats, :in_repeating_group,
          :data_type,
          :required,
          :profile

        # def initialize(fdp, name, config, parent)
        def initialize(config)
          super
          @datahash = config.hash["[config]"]
          set_id
          @data_type = set_datatype
          @required = set_required
        end

        def valsrctype = @valsrctype ||=
                           CCU::Fields::ValueSources::TypeExtractor.call(
                             datahash
                           )

        def value_list = @value_list ||= set_value_list

        def value_sources = @value_sources ||= set_value_sources

        def to_h
          attrs = attr_readers.map { |e| "@" + e.to_s }.map { |e| e.to_sym }
          h = {}
          attrs.each { |a| h[a] = instance_variable_get(a) }
          h
        end

        def csv_header
          %w[profile record_type namespace field_id field_name
            schema_path required repeats group_repeats data_type
            data_source_type data_source_name option_list_values]
        end

        def rectype
          @config.rectype
        end

        def to_csv
          arr = [@config.profile, @config.rectype, @config.ns.literal,
            @id]
          arr << (@name || "")
          arr << (@schema_path ? @schema_path.join(" > ") : "")
          arr << (@required || "")
          arr << (@repeats || "")
          arr << (@in_repeating_group || "")
          arr << (@data_type || "")
          if value_sources
            arr << value_sources.map(&:csv_type).compact.uniq.join(", ")
            arr << value_sources.map(&:csv_name).compact.uniq.join(", ")
          else
            2.times { arr << "" }
          end
          arr << (value_list ? value_list.join(", ") : "")
          arr
        end

        def inspect
          omit = %i[@config @profile @hash @parent @datahash @name @ns_for_id]
          attributes = instance_variables.unshift([])
            .inject do |info, attribute|
            if omit.include?(attribute)
              info
            else
              info << "#{attribute}=#{instance_variable_get(attribute).inspect}"
            end
          end

          %(#<#{self.class}:#{object_id} #{attributes.join(", ")}>)
        end

        private

        attr_reader :datahash

        def set_required
          if @datahash.dig("required") && @datahash["required"] == true
            "y"
          else
            "n"
          end
        end

        def set_value_sources
          return [] unless valsrctype

          sources = CCU::Fields::ValueSources::SourceExtractor.call(
            valsrctype, @datahash, @config.profile_object
          )

          sources.select!(&:configured?) if valsrctype == "authority"
          return [CCU::ValueSources::NoSource.new] if sources.empty?

          sources
        end

        def set_value_list
          return [] unless valsrctype == "option list" &&
            value_sources.first.respond_to?(:options)

          value_sources.first.options
        end

        def set_datatype
          val = @datahash.dig("dataType")
          val = val.sub("DATA_TYPE_", "") if val
          case val
          when nil
            return "structured date group" if is_structured_date?
            "string"
          when "INT"
            "integer"
          when "FLOAT"
            "float"
          when "BOOL"
            "boolean"
          when "DATE"
            "date"
          when "STRING"
            "string"
          when "STRUCTURED_DATE"
            "structured date group"
          else
            "TODO: handle unknown datatype: #{val}"
          end
        end

        def set_id
          if @parent.is_a?(CCU::Fields::Def::Grouping) &&
              @parent.is_structured_date?
            @id = "ext.structuredDate.#{@name}"
          elsif @parent.is_a?(CCU::Fields::Def::Grouping) &&
              @parent.schema_path.include?("localityGroupList")
            @id = "ext.locality.#{@name}"
          elsif @datahash.dig("extensionName")
            @id = "ext.#{@datahash.dig("extensionName")}.#{@name}"
            # @id = case @datahash["extensionName"]
            # when "structuredDate"
            #   "ext.structuredDate.#{@name}"
            # when "dimension"
            #   "ext.dimension.#{@name}"
            # when "address"
            #   "ext.address.#{@name}"
            # when "locality"
            #   "ext.locality.#{@name}"
            # else
            #   binding.pry
            # end
          elsif @id == "approvalGroupField.approvalGroup"
            CCU.upgrade_warner.call(
              target_version: "8_1",
              issue: "DRYD-863"
            )
            @id = "#{@ns.sub("ns2:", "")}.approvalGroup"
          else
            @id = "#{@ns_for_id.sub("ns2:", "")}.#{@name}"
          end
        end
      end
    end
  end
end
