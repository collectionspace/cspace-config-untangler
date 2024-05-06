# frozen_string_literal: true

require_relative "../track_attributes"

module CspaceConfigUntangler
  module Forms
    class Field
      include CCU::TrackAttributes
      attr_reader :profile, :rectype, :name, :ns, :ns_for_id, :panel, :ui_path,
        :id, :to_csv

      def initialize(propsobj)
        @form = propsobj.form

        @profile = @form.rectype.profile.name
        @rectype = @form.rectype.name
        @name = propsobj.name
        @panel = propsobj.panel
        @ns = propsobj.ns
        @ns_for_id = propsobj.ns_for_id
        if ns_for_id.is_a?(String)
          @id = "#{@ns_for_id.sub("ns2:", "")}.#{@name}"
        else
          @id = "#{profile} #{rectype} #{name}"
          CCU.log.error("FORM STRUCTURE: NAMESPACE EXTRACTION: missing or "\
                       "malformed namespace extracted for #{id}")
        end
        @ui_path = propsobj.ui_path
        @to_csv = format_csv
        clean_up
      end

      def csv_header
        %w[profile record_type panel ui_path field_id field_name]
      end

      def to_h
        attrs = attr_readers.map { |e| "@" + e.to_s }.map { |e| e.to_sym }
        h = {}
        attrs.each { |a| h[a] = instance_variable_get(a) }
        h.delete(:@to_csv)
        h
      end

      private

      def format_csv
        arr = [@profile, @rectype]
        if @ui_path
          path = @ui_path.clone
          arr << path.shift
          arr << path.compact.join(" > ")
        else
          arr << ""
          arr << ""
        end
        arr << (@id || "")
        arr << (@name || "")
        arr
      end

      def clean_up
        @form = @form.name
      end
    end
  end
end
