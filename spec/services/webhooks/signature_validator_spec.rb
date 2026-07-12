# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::SignatureValidator do
  let(:secret) { 'test-channel-secret' }
  let(:validator) { described_class.new(secret) }
  let(:body) { '{"events":[]}' }

  def sign(body, secret)
    Base64.strict_encode64(
      OpenSSL::HMAC.digest(OpenSSL::Digest.new('SHA256'), secret, body)
    )
  end

  describe '#valid?' do
    context 'when the signature is blank' do
      it 'returns false for nil' do
        expect(validator.valid?(body, nil)).to be false
      end

      it 'returns false for an empty string' do
        expect(validator.valid?(body, '')).to be false
      end
    end

    context 'when the signature matches the computed HMAC' do
      it 'returns true' do
        expect(validator.valid?(body, sign(body, secret))).to be true
      end
    end

    context 'when the signature does not match' do
      it 'returns false' do
        expect(validator.valid?(body, sign(body, 'wrong-secret'))).to be false
      end
    end
  end
end
