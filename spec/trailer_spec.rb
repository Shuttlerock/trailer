# frozen_string_literal: true

RSpec.describe Trailer do
  it 'has a version number' do
    expect(Trailer::VERSION).not_to be nil
  end
end
