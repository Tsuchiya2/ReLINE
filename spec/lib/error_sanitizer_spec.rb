# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ErrorSanitizer do
  describe '.sanitize' do
    it 'チャネル情報を伏せる' do
      expect(described_class.sanitize('channel_token: abcdef')).to eq(described_class::MASK)
    end

    it 'Authorization ヘッダを伏せる' do
      expect(described_class.sanitize('authorization: Bearer xyz')).to include(described_class::MASK)
    end

    it 'アクセストークンを伏せる' do
      expect(described_class.sanitize('Bearer super-secret')).to eq(described_class::MASK)
    end

    it '機密が含まれない文言はそのまま返す' do
      expect(described_class.sanitize('通信に失敗しました')).to eq('通信に失敗しました')
    end
  end

  describe '.format' do
    let(:exception) do
      raise StandardError, 'channel_secret: secret-value'
    rescue StandardError => e
      e
    end

    it 'どこで起きたかを添える' do
      expect(described_class.format(exception, 'Webhook')).to include('<Webhook>')
    end

    it '例外の種類を添える' do
      expect(described_class.format(exception, 'Webhook')).to include('StandardError')
    end

    it 'メッセージの機密を伏せる' do
      expect(described_class.format(exception, 'Webhook')).to include(described_class::MASK)
    end

    it 'バックトレースを決められた行数だけ載せる' do
      backtrace = described_class.format(exception, 'Webhook').lines.drop(4)

      expect(backtrace.size).to eq(described_class::BACKTRACE_LINES)
    end

    it 'バックトレースが無い例外でも整形できる' do
      expect { described_class.format(StandardError.new('エラー'), 'Webhook') }.not_to raise_error
    end
  end
end
