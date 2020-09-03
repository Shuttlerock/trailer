# frozen_string_literal: true

RSpec.describe Trailer::Configuration do
  subject { described_class.new }

  describe 'initialize' do
    it 'sets some default values' do
      expect(subject.aws_region).to eq 'us-east-1'
    end
  end

  describe 'tag_fields' do
    it 'converts fields to symbols' do
      subject.tag_fields = ['name']
      expect(subject.tag_fields).to match [:name]
    end

    it 'ensures an array' do
      subject.tag_fields = 'name'
      expect(subject.tag_fields).to match [:name]
    end

    it 'flattens arrays' do
      subject.tag_fields = [%w[name address], 'age']
      expect(subject.tag_fields).to match %i[name address age]
    end
  end
end
