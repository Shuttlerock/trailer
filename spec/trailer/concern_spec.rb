# frozen_string_literal: true

class Model
  def self.column_names
    %i[id name]
  end

  def id
    123
  end

  def name
    'user'
  end
end

class Tester
  include Trailer::Concern

  def test_event(resource)
    trace_event(:save, resource, {}) do
      'tested event'
    end
  end

  def test_class(resource)
    trace_class(resource, {}) do
      'tested class'
    end
  end

  def test_method(resource)
    trace_method(resource, {}) do
      'tested method'
    end
  end

  def current_member
    OpenStruct.new(id: 456)
  end
end

RSpec.describe Trailer::Concern do
  subject { Tester.new }

  let(:store) { RequestStore.store[:trailer] }

  before do
    allow(Process).to receive(:clock_gettime).and_return(0)
    RequestStore.store[:trailer] = Trailer.new
    allow(store).to receive(:write)
  end

  describe '#trace_class' do
    it 'returns the result of the block' do
      expect(subject.test_class(Model.new)).to eq 'tested class'
    end

    it 'sends the event to storage' do
      subject.test_class(Model.new)
      expect(store).to have_received(:write).with(hash_including(event: Tester.name))
    end
  end

  describe '#trace_event' do
    it 'returns the result of the block' do
      expect(subject.test_event(Model.new)).to eq 'tested event'
    end

    it 'sends the event to storage' do
      subject.test_event(Model.new)
      expected = {
        duration: 0,
        event:    :save,
        model_id: 123,
        name:     'user',
        resource: 'model',
      }
      expect(store).to have_received(:write).with(expected)
    end

    it 'allows hash resources' do
      subject.test_event({ id: 123, name: 'user' })
      expected = {
        duration: 0,
        event:    :save,
        name:     'user',
        resource: 'hash',
      }
      expect(store).to have_received(:write).with(expected)
    end

    it 'allows string resources' do
      subject.test_event('user')
      expected = {
        duration: 0,
        event:    :save,
        resource: 'user',
      }
      expect(store).to have_received(:write).with(expected)
    end

    it 'allows symbol resources' do
      subject.test_event(:user)
      expected = {
        duration: 0,
        event:    :save,
        resource: :user,
      }
      expect(store).to have_received(:write).with(expected)
    end

    it 'allows fields to be auto-tagged' do
      Trailer.configure { |config| config.auto_tag_fields = /(_id|_at|_user_ids)$/.freeze }
      data = { post_id: 123, created_at: Time.now.to_s, deleted_user_ids: [1, 2, 3] }
      subject.test_event(data)
      expect(store).to have_received(:write).with(hash_including(data))
    end

    it 'allows fields to be explicitly tagged' do
      data = { price: 111, status: 'saved' }
      Trailer.configure { |config| config.tag_fields = %w[price status] }
      subject.test_event(data)
      expect(store).to have_received(:write).with(hash_including(data))
    end

    it 'tags the current user' do
      Trailer.configure { |config| config.current_user_method = :current_member }
      subject.test_event(Model.new)
      expect(store).to have_received(:write).with(hash_including(current_member_id: 456))
    end

    it 'records the duration of the trace' do
      allow(Process).to receive(:clock_gettime).and_return(123, 456)
      subject.test_event(Model.new)
      expect(store).to have_received(:write).with(hash_including(duration: 333_000))
    end
  end

  describe '#trace_method' do
    it 'returns the result of the block' do
      expect(subject.test_method(Model.new)).to eq 'tested method'
    end

    it 'sends the event to storage' do
      subject.test_method(Model.new)
      expect(store).to have_received(:write).with(hash_including(event: 'Tester#test_method'))
    end
  end
end
