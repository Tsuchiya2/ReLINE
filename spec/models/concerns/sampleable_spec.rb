# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sampleable, type: :model do
  describe '.sample_body' do
    it 'カテゴリに属する本文を返す' do
      create(:content, category: :free, body: '自由なことば')

      expect(Content.sample_body(:free)).to eq('自由なことば')
    end

    it '別のカテゴリの本文は返さない' do
      create(:content, category: :contact, body: '連絡のことば')

      expect(Content.sample_body(:free)).to be_nil
    end

    it '記録が無ければ nil を返す' do
      expect(AlarmContent.sample_body(:contact)).to be_nil
    end
  end

  describe '.bodies_by_category' do
    before do
      create(:content, category: :contact, body: '連絡のことば')
      create(:content, category: :free, body: '自由なことば')
      create(:content, category: :free, body: 'もうひとつの自由なことば')
    end

    it 'カテゴリごとに本文をまとめる' do
      expect(Content.bodies_by_category).to eq(
        contact: ['連絡のことば'],
        free: %w[自由なことば もうひとつの自由なことば]
      )
    end

    it '記録が無ければ空になる' do
      expect(AlarmContent.bodies_by_category).to eq({})
    end
  end
end
