# frozen_string_literal: true

RSpec.describe Trailer::Configuration do
  describe 'initialize' do
    subject { described_class.new }

    it 'sets some default values' do
      expect(subject.aws_region).to eq 'us-east-1'
    end
  end
end
