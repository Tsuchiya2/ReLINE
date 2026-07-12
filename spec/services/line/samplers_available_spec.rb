# frozen_string_literal: true

require 'rails_helper'

# Covers the #available? branches for both content samplers.
RSpec.describe Line::ContentSampler do
  let(:sampler) { described_class.new }

  describe '#available?' do
    it 'returns true when content exists and reuses the cache on subsequent calls' do
      create(:content, category: :free)

      expect(sampler.available?(:free)).to be true # cache miss -> refresh
      expect(sampler.available?(:free)).to be true # cache hit -> skip refresh
    end

    it 'returns false when no content exists for the category' do
      expect(sampler.available?(:text)).to be false
    end
  end
end

RSpec.describe Line::AlarmContentSampler do
  let(:sampler) { described_class.new }

  describe '#available?' do
    it 'returns true when alarm content exists and reuses the cache on subsequent calls' do
      create(:alarm_content, category: :contact)

      expect(sampler.available?(:contact)).to be true
      expect(sampler.available?(:contact)).to be true
    end

    it 'returns false when no alarm content exists for the category' do
      expect(sampler.available?(:text)).to be false
    end
  end
end
