# frozen_string_literal: true

RSpec.describe Trailer::Storage::CloudWatch do
  subject      { described_class.new }

  let(:client) { instance_double(Aws::CloudWatchLogs::Client) }
  let(:data)   { { some: :data } }
  let(:name)   { Trailer.config.application_name }

  before do
    Trailer.configure do |config|
      config.application_name = 'studio'
    end
    allow(Aws::CloudWatchLogs::Client).to receive(:new).and_return(client)
    allow(client).to receive(:create_log_group)
    allow(client).to receive(:create_log_stream)
    allow(client).to receive(:put_log_events)
    allow(client).to receive(:describe_log_groups).and_return(OpenStruct.new(log_groups: []))
    allow(client).to receive(:describe_log_streams).and_return(OpenStruct.new(log_streams: []))
  end

  describe '#initialize' do
    it 'creates a log group if none exists' do
      subject
      expect(client).to have_received(:create_log_group).with(log_group_name: name)
    end

    it 'uses an existing log group if there is one' do
      log_group = OpenStruct.new(log_group_name: name)
      allow(client).to receive(:describe_log_groups).and_return(OpenStruct.new(log_groups: [log_group]))
      subject
      expect(client).not_to have_received(:create_log_group)
    end

    it 'creates a log stream if none exists' do
      subject
      expect(client).to have_received(:create_log_stream).with(
        log_group_name:  name,
        log_stream_name: name,
      )
    end

    it 'uses an existing log stream if there is one' do
      log_stream = OpenStruct.new(log_stream_name: name)
      allow(client).to receive(:describe_log_streams).and_return(OpenStruct.new(log_streams: [log_stream]))
      subject
      expect(client).not_to have_received(:create_log_stream)
    end
  end

  describe '#flush' do
    it 'does nothing if the write queue is empty' do
      subject.send(:messages=, [])
      subject.flush
      expect(client).not_to have_received(:put_log_events)
    end

    it 'pushes the queued data to AWS CloudWatch' do
      subject.write(data)
      subject.flush
      expected = { log_events:      [{ message: data.to_json, timestamp: an_instance_of(Integer) }],
                   log_group_name:  name,
                   log_stream_name: name,
                   sequence_token:  nil }
      expect(client).to have_received(:put_log_events).with(expected)
    end

    it 'stores the resulting sequence token for use in the next write' do
      token = 'next-token'
      allow(client).to receive(:put_log_events).and_return(OpenStruct.new(next_sequence_token: token))
      expect(subject.send(:sequence_token)).to be_nil
      subject.send(:messages=, [data])
      subject.flush
      expect(subject.send(:sequence_token)).to eq token
      # The next write should use the token.
      subject.send(:messages=, [data])
      subject.flush
      expect(client).to have_received(:put_log_events).with(hash_including(sequence_token: token))
    end

    it 'fetches a new token if someone else writes first' do
      subject.write(data)
      allow(subject).to receive(:log_stream).and_return({ upload_sequence_token: 'another-token' })
      allow(subject).to receive(:sequence_token=)
      err = Aws::CloudWatchLogs::Errors::InvalidSequenceTokenException.new(:context, 'something went wrong')
      # This is kind of hard to test, but we want to throw an exception the first time only, and then retry.
      # Perhaps there's a better way to do this?
      raised = false
      expect(client).to receive(:put_log_events) do # rubocop:disable RSpec/MessageSpies
        raise err unless raised && (raised = true)
      end
      subject.flush
      expect(subject).to have_received(:sequence_token=).with('another-token')
    end

    it 'empties the write queue' do
      subject.write(data)
      expect(subject.send(:messages)).not_to be_empty
      subject.flush
      expect(subject.send(:messages)).to be_empty
    end
  end

  describe '#write' do
    it 'adds data to the write queue' do
      expect(subject.send(:messages)).to be_empty
      subject.write(data)
      expect(subject.send(:messages)).to match [{ message: data.to_json, timestamp: an_instance_of(Integer) }]
    end

    it 'does nothing if the message is empty' do
      expect(subject.send(:messages)).to be_empty
      subject.write([])
      expect(subject.send(:messages)).to be_empty
    end
  end
end
