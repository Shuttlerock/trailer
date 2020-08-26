# frozen_string_literal: true

require 'trailer/utility'

module Trailer
  module Concern
    # Traces the given block, with optional tags.
    #
    # @param name     [String]                    - Describes the generic kind of operation being done (eg. 'web_request', or 'parse_request').
    # @param resource [ApplicationRecord, String] - *Ideally just pass an ActiveRecord instance here.*
    #                                               The resource being operated on, or its name. Usually domain-specific, such as a model
    #                                               instance, query, etc (eg. current_user, 'Article#submit', 'http://example.com/articles').
    # @param tags     Hash                        - Extra tags which should be tracked (eg. { method: 'GET' }).
    def with_trail(event, resource, **tags) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return yield unless Trailer.enabled?

      event           = Trailer::Utility.resource_name(event) unless event.is_a?(String)
      resource_name   = resource if resource.is_a?(String)
      resource_name ||= Trailer::Utility.resource_name(resource)
      resource_name ||= 'unknown'

      # If column_names() is available, we are probably looking at an ActiveRecord instance.
      if resource.class.respond_to?(:column_names)
        resource.class.column_names.each do |field|
          tags[field] ||= resource.public_send(field) if field.match?(Trailer.config.auto_tag_fields)
        end
      elsif resource.respond_to?(:to_h)
        # This handles other types of data, such as GraphQL input objects.
        stringified = resource.to_h.stringify_keys
        stringified.each_key do |key|
          tags[key] ||= stringified[key] if key.to_s.match?(Trailer.config.auto_tag_fields) || Trailer.config.tag_fields.include?(key)
        end
      end

      # Tag fields that have been explicitly included.
      Trailer.config.tag_fields.each do |field|
        tags[field] ||= resource.public_send(field) if resource.respond_to?(field)
      end

      tags["#{resource_name}_id"] ||= resource.id if resource.respond_to?(:id)

      # Record the ID of the current user, if configured.
      if Trailer.config.current_user_method && respond_to?(Trailer.config.current_user_method, true)
        user = send(Trailer.config.current_user_method)
        tags["#{Trailer.config.current_user_method}_id"] = user.id if user&.respond_to?(:id)
      end

      # Record how long the operation takes, in milliseconds.
      started_at      = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result          = yield
      tags[:duration] = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1_000).ceil

      # Put the keys in alphabetical order, with the event and resource first.
      sorted = { event: event, resource: resource_name }.merge(tags.sort_by { |key, _val| key.to_s }.to_h)
      RequestStore.store[:trailer].write(sorted)

      result
    end
  end
end
