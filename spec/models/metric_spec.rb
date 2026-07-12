# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Metric, type: :model do
  describe '.aggregate' do
    it 'returns aggregated statistics for matching metrics' do
      described_class.create!(name: 'cache_hit', value: 10)
      described_class.create!(name: 'cache_hit', value: 30)

      result = described_class.aggregate('cache_hit')

      expect(result[:count]).to eq(2)
      expect(result[:total].to_f).to eq(40.0)
      expect(result[:average].to_f).to eq(20.0)
      expect(result[:minimum].to_f).to eq(10.0)
      expect(result[:maximum].to_f).to eq(30.0)
    end

    it 'returns an empty hash when the aggregate query yields no row' do
      # The aggregate query normally returns a row even with no matches, so the
      # nil-guard is only reachable by forcing `take` to return nil.
      relation = instance_double(ActiveRecord::Relation, take: nil)
      scoped = instance_double(ActiveRecord::Relation, select: relation)
      allow(described_class).to receive(:by_name).with('missing').and_return(scoped)

      expect(described_class.aggregate('missing')).to eq({})
    end
  end
end
