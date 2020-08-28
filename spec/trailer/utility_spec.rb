# frozen_string_literal: true

RSpec.describe Trailer::Utility do
  subject { described_class }

  describe '.demodulize' do
    it 'demodulizes the input' do
      expect(described_class.demodulize('ActiveSupport::Inflector::Inflections')).to eq 'Inflections'
      expect(described_class.demodulize('Inflections')).to eq 'Inflections'
      expect(described_class.demodulize('::Inflections')).to eq 'Inflections'
      expect(described_class.demodulize('')).to eq ''
    end
  end

  describe '.underscore' do
    it 'underscores the input' do
      expect(described_class.underscore('ActiveModel')).to eq 'active_model'
      expect(described_class.underscore('ActiveModel::Errors')).to eq 'active_model/errors'
    end
  end

  describe '.resource_name' do
    it 'underscores and demodulizes the input' do
      expect(described_class.resource_name(Trailer)).to eq 'module'
      expect(described_class.resource_name(Trailer::Recorder.new(nil))).to eq 'recorder'
      expect(described_class.resource_name('my-resource')).to eq 'string'
    end
  end
end
