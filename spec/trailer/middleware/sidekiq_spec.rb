# frozen_string_literal: true

RSpec.describe Trailer::Middleware::Sidekiq do
  subject { described_class.new }

  def call!
    subject.call(double, double, double) { true }
  end

  describe '#call' do
    context 'trailer enabled' do
      it 'instantiates a trailer instance' do
        expect(RequestStore.store[:trailer]).to be_nil
        call!
        expect(RequestStore.store[:trailer]).to be_a(Trailer::Recorder)
      end

      it 'starts and finishes a trace' do
        trailer = RequestStore.store[:trailer] = Trailer.new
        allow(trailer).to receive(:start)
        allow(trailer).to receive(:finish)
        call!
        expect(trailer).to have_received(:start).ordered
        expect(trailer).to have_received(:finish).ordered
      end

      it 'records exceptions' do
        err     = StandardError.new('something went wrong')
        trailer = RequestStore.store[:trailer] = Trailer.new
        allow(trailer).to receive(:start).and_raise(err)
        allow(trailer).to receive(:add_exception)
        expect do
          call!
        end.to raise_exception(err)
        expect(trailer).to have_received(:add_exception).with(err)
      end
    end

    context 'trailer disabled' do
      it 'does not instantiate a trailer instance' do
        Trailer.configure { |config| config.enabled = false }
        allow(Trailer).to receive(:new)
        call!
        expect(RequestStore.store[:trailer]).to be_nil
        expect(Trailer).not_to have_received(:new)
      end
    end
  end
end
