# frozen_string_literal: true

require 'trailer/utility'

module Trailer::Concern
  # Traces the given block, with optional tags.
  #
  # @param name     [String]                    - Describes the generic kind of operation being done (eg. 'web.request', or 'request.parse').
  # @param resource [ApplicationRecord, String] - *Ideally just pass an ActiveRecord instance here.*
  #                                               Name of the resource or action being operated on. Traces with the same resource value will be
  #                                               grouped together for the purpose of metrics (but still independently viewable.) Usually domain
  #                                               specific, such as a URL, query, request, etc.
  #                                               (eg. 'Article#submit', http://example.com/articles/list).
  # @param tags     Hash                        - Extra tags which should be tracked (eg. { 'http.method' => 'GET' }).
  def with_trail(event, resource, tags: {}, &block) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    yield block and return unless Trailer.config.enabled

    started_at        = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    resource_name     = Trailer::Utility.resource_name(resource)
    tags[:event]    ||= event
    tags[:resource] ||= resource if resource.is_a?(String)
    tags[:resource] ||= resource_name if resource.present?
    tags[:resource] ||= 'unknown'

    unless resource.is_a?(String)
      # Tag anything that looks like an ID / date etc for ActiveRecord instances.
      if resource.class.respond_to?(:column_names)
        resource.class.column_names.each do |field|
          tags[field] ||= resource.public_send(field) if field.match?(Trailer.config.auto_tag_fields)
        end
      end

      # Tag anything else that might be useful.
      Trailer.config.tag_fields.each do |field|
        tags[field] ||= resource.public_send(field) if resource.respond_to?(field)
      end

      tags["#{resource_name}_id"] ||= resource.id if resource.respond_to?(:id)
    end

    yield block

    # Record how long the operation took, in milliseconds.
    tags[:duration] = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1_000).ceil

    # Put the keys in alphabetical order, with the event and resource first.
    sorted = tags.sort_by { |key, _value| [key.to_s == 'event' ? 0 : 1, key.to_s == 'resource' ? 0 : 1, key.to_s] }.to_h
    RequestStore.store[:trailer].write(sorted)
  end
end
