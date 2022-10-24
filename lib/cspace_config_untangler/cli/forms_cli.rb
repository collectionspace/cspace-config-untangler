require_relative 'helpers'

module CspaceConfigUntangler
  module Cli
    class FormsCli < Thor
      include CCU::Cli::Helpers

      desc 'disabled', 'List disabled forms in given profiles/record types'
      option :rectypes, desc: 'Comma separated list (no spaces) of record '\
        'types to include. Defaults to all.',
        default: 'all',
        aliases: '-r'
      def disabled
        rt = options[:rectypes] == 'all' ? [] : options[:rectypes].split(',')
        get_profiles.map do |profile|
          CCU::Profile.new(profile: profile, rectypes: rt)
            .rectypes
            .map{ |rt| rt.forms.values }
        end
          .flatten
          .select{ |form| form.disabled? }
          .each{ |form| puts form.id }
      end
    end
  end
end
