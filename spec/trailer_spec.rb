# frozen_string_literal: true

RSpec.describe Trailer do
  subject { described_class }

  it 'has a version number' do
    expect(subject::VERSION).not_to be nil
  end

  describe '.configure' do
    it 'allows a block to be passed to configure the gem' do
      application_name = SecureRandom.uuid
      subject.configure do |config|
        config.application_name = application_name
      end
      expect(subject.config.application_name).to eq application_name
    end
  end

  describe '.enabled?' do
    it 'allows the gem to be disabled' do
      subject.configure { |config| config.enabled = false }
      expect(subject.enabled?).to be false
      subject.configure { |config| config.enabled = true }
      expect(subject.enabled?).to be true
    end
  end

  describe '.new?' do
    it 'returns nothing if the gem is not enabled' do
      subject.configure { |config| config.enabled = false }
      expect(subject.new).to be_nil
    end

    it 'raises an error if configure() has not been called' do
      subject.instance_variable_set(:@storage, nil)
      expect do
        subject.new
      end.to raise_exception(Trailer::Error, 'Trailer.configure must be run before recording')
    end

    it 'returns a new recorder' do
      expect(subject.new).to be_a(Trailer::Recorder)
    end
  end
end
