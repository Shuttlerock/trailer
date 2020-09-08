# frozen_string_literal: true

RSpec.describe Trailer::Recorder do
  subject       { described_class.new(storage) }

  let(:storage) { instance_double(Trailer::Storage::Null) }

  before do
    Trailer.configure do |config|
      config.environment  = 'test'
      config.host_name    = 'web.1'
      config.service_name = 'studio'
    end
    allow(Trailer.config).to receive(:storage).and_return(storage)
    allow(storage).to receive(:async).and_return(storage)
    subject.start
  end

  def trace_id
    subject.send(:trace_id)
  end

  describe '#add_exception' do
    let(:err)      { StandardError.new('something went wrong') }
    let(:expected) do
      {
        environment:  'test',
        exception:    StandardError.name,
        host_name:    'web.1',
        service_name: 'studio',
        message:      err.message,
        trace:        err.backtrace,
        trace_id:     trace_id,
      }
    end

    before do
      allow(storage).to receive(:write)
      backtrace = ['line one']
      allow(err).to receive(:backtrace).and_return(backtrace)
    end

    it 'writes the exception to storage' do
      subject.add_exception(err)
      expect(storage).to have_received(:write).with(expected)
    end

    it 'includes tags that have been discovered so far' do
      subject.write(order_id: 5)
      subject.write(order_id: 6, user_id: 7)
      subject.add_exception(err)
      expect(storage).to have_received(:write).with(expected.merge(order_id: 6, user_id: 7))
    end
  end

  describe '#finish' do
    it 'flushes data to storage' do
      allow(storage).to receive(:flush)
      expect(subject.send(:trace_id)).not_to be_nil
      subject.finish
      expect(storage).to have_received(:flush)
      expect(trace_id).to be_nil
    end
  end

  describe '#start' do
    it 'raises an error if the previous trace has not finished' do
      expect do
        subject.start
      end.to raise_exception(Trailer::Error, 'finish() must be called before a new trace can be started')
    end

    it 'starts a new trace' do
      subject.instance_variable_set(:@trace_id, nil)
      subject.start
      expect(trace_id).not_to be_nil
    end
  end

  describe '#write' do
    let(:data) { { some: :data } }

    it 'raises an error if the trace has not started' do
      subject.instance_variable_set(:@trace_id, nil)
      expect do
        subject.write(data)
      end.to raise_exception(Trailer::Error, 'start() must be called before write()')
    end

    it 'raises an error if invalid data is passed' do
      expect do
        subject.write('invalid')
      end.to raise_exception(Trailer::Error, 'data must be an instance of Hash')
    end

    it 'writes the data to storage' do
      allow(storage).to receive(:write)
      subject.write(data)
      expected = {
        environment:  'test',
        host_name:    'web.1',
        service_name: 'studio',
        some:         :data,
        trace_id:     trace_id,
      }
      expect(storage).to have_received(:write).with(expected)
    end
  end
end
