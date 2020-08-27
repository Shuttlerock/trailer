# frozen_string_literal: true

require 'trailer/utility'

module Trailer
  module Concern
    # Traces the given block, with an event name, plus optional resource and tags.
    #
    # @param event    [String]                    - Describes the generic kind of operation being done (eg. 'web_request', or 'parse_request').
    # @param resource [ApplicationRecord, String] - *Ideally just pass an ActiveRecord instance here.*
    #                                               The resource being operated on, or its name. Usually domain-specific, such as a model
    #                                               instance, query, etc (eg. current_user, 'Article#submit', 'http://example.com/articles').
    # @param tags     Hash                        - Extra tags which should be tracked (eg. { method: 'GET' }).
    def trace_event(event, resource = nil, **tags, &block) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return yield block unless Trailer.enabled?

      event = Trailer::Utility.resource_name(event) unless event.is_a?(String)

      unless resource.nil?
        resource_name   = resource if resource.is_a?(String)
        resource_name ||= Trailer::Utility.resource_name(resource)

        # If column_names() is available, we are probably looking at an ActiveRecord instance.
        if resource.class.respond_to?(:column_names)
          resource.class.column_names.each do |field|
            tags[field] ||= resource.public_send(field) if field.match?(Trailer.config.auto_tag_fields)
          end
        elsif resource.respond_to?(:to_h)
          # This handles other types of data, such as GraphQL input objects.
          resource.to_h.stringify_keys.each do |key, value|
            tags[key] ||= value if key.to_s.match?(Trailer.config.auto_tag_fields) || Trailer.config.tag_fields.include?(key)
          end
        end

        # Tag fields that have been explicitly included.
        Trailer.config.tag_fields.each do |field|
          tags[field] ||= resource.public_send(field) if resource.respond_to?(field)
        end

        tags["#{resource_name}_id"] ||= resource.id if resource.respond_to?(:id)
      end

      # Record the ID of the current user, if configured.
      if Trailer.config.current_user_method && respond_to?(Trailer.config.current_user_method, true)
        user = send(Trailer.config.current_user_method)
        tags["#{Trailer.config.current_user_method}_id"] = user.id if user&.respond_to?(:id)
      end

      # Record how long the operation takes, in milliseconds.
      started_at      = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result          = yield block
      tags[:duration] = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1_000).ceil

      # Put the keys in alphabetical order, with the event and resource first.
      sorted = { event: event, resource: resource_name }.merge(tags.sort_by { |key, _val| key.to_s }.to_h)
      RequestStore.store[:trailer].write(sorted)

      result
    end

    # Traces the given block with optional resource and tags. It will generate an event name based on the
    # calling class, and pass the information on to trace_event().
    #
    # @param resource [ApplicationRecord, String] - *Ideally just pass an ActiveRecord instance here.*
    #                                               The resource being operated on, or its name. Usually domain-specific, such as a model
    #                                               instance, query, etc (eg. current_user, 'Article#submit', 'http://example.com/articles').
    # @param tags     Hash                        - Extra tags which should be tracked (eg. { method: 'GET' }).
    def trace_class(resource = nil, **tags, &block)
      trace_event(self.class.name, resource, **tags) do
        yield block
      end
    end

    # Traces the given block with optional resource and tags. It will generate an event name based on the
    # calling method and class, and pass the information on to trace_event().
    #
    # @param resource [ApplicationRecord, String] - *Ideally just pass an ActiveRecord instance here.*
    #                                               The resource being operated on, or its name. Usually domain-specific, such as a model
    #                                               instance, query, etc (eg. current_user, 'Article#submit', 'http://example.com/articles').
    # @param tags     Hash                        - Extra tags which should be tracked (eg. { method: 'GET' }).
    def trace_method(resource = nil, **tags, &block)
      calling_klass  = self.class.name
      calling_method = caller(1..1).first[/`.*'/][1..-2]
      trace_event("#{calling_klass}##{calling_method}", resource, **tags) do
        yield block
      end
    end
  end
end
