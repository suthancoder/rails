module ActionDispatch
  module Http
    class ParameterFilter
      def initialize(filters)
        @filters = filters
      end

      def filter(params)
        if @filters.empty?
          params.dup
        else
          compiled_filter.call(params)
        end
      end

    private

      FILTERED = '[FILTERED]'.freeze

      def compiled_filter
        @compiled_filter ||= begin
          regexps, blocks = compile_filter

          lambda do |original_params|
            filtered_params = {}

            original_params.each do |key, value|
              if regexps.find { |r| key =~ r }
                value = FILTERED
              elsif value.is_a?(Hash)
                value = filter(value)
              elsif value.is_a?(Array)
                value = value.map { |v| v.is_a?(Hash) ? filter(v) : v }
              elsif blocks.present?
                key = key.dup
                value = value.dup if value.duplicable?
                blocks.each { |b| b.call(key, value) }
              end

              filtered_params[key] = value
            end

            filtered_params
          end
        end
      end

      def compile_filter
        strings, regexps, blocks = [], [], []

        @filters.each do |item|
          case item
          when Proc
            blocks << item
          when Regexp
            regexps << item
          else
            strings << item.to_s
          end
        end

        regexps << Regexp.new(strings.join('|'), true) unless strings.empty?
        [regexps, blocks]
      end

    end
  end
end
