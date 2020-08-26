# frozen_string_literal: true

module Trailer
  class Utility
    class << self
      # Copied from ActiveSupport::Inflector to avoid introducing an extra dependency.
      #
      # @param path [String] The path to demodulize.
      #
      # @see https://apidock.com/rails/ActiveSupport/Inflector/demodulize
      #
      # Removes the module part from the expression in the string.
      #
      #   demodulize('ActiveSupport::Inflector::Inflections') # => "Inflections"
      #   demodulize('Inflections')                           # => "Inflections"
      #   demodulize('::Inflections')                         # => "Inflections"
      #   demodulize('')                                      # => ""
      def demodulize(path)
        path = path.to_s
        if (i = path.rindex('::'))
          path[(i + 2)..]
        else
          path
        end
      end

      # Copied from ActiveSupport::Inflector to avoid introducing an extra dependency.
      #
      # @param camel_cased_word [String] The word to underscore.
      #
      # @see https://apidock.com/rails/v5.2.3/ActiveSupport/Inflector/underscore
      #
      # Makes an underscored, lowercase form from the expression in the string.
      #
      # Changes '::' to '/' to convert namespaces to paths.
      #
      #   underscore('ActiveModel')         # => "active_model"
      #   underscore('ActiveModel::Errors') # => "active_model/errors"
      def underscore(camel_cased_word)
        return camel_cased_word unless /[A-Z-]|::/.match?(camel_cased_word)

        word = camel_cased_word.to_s.gsub('::', '/')
        word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
        word.tr!('-', '_')
        word.downcase!
        word
      end

      # Creates a name for the given resource instance, suitable for recording in the trace.
      #
      # @param resource [Object] The resource instance to derive a name for.
      def resource_name(resource)
        return resource unless resource.respond_to?(:name)

        underscore(demodulize(resource.name))
      end
    end
  end
end
