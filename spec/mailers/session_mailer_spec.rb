# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionMailer, type: :mailer do
  before do
    # ApplicationMailer resolves the recipient from credentials, which are not
    # decryptable without the master key. Stub only the operator entry so the
    # rest of the credentials object stays intact for view/URL rendering.
    allow(Rails.application.credentials).to receive(:operator).and_return(email: 'operator@example.com')
  end

  describe '#notice' do
    let(:operator) { create(:operator, :locked, name: 'Locked Operator') }
    let(:mail) { described_class.notice(operator, '203.0.113.5') }

    it 'sets the subject' do
      expect(mail.subject).to eq('【Warning】ロック状態のアカウントにアクセスがありました')
    end

    it 'delivers to the operator address from credentials' do
      expect(mail.to).to eq(['operator@example.com'])
    end

    it 'includes the operator name in the body' do
      expect(mail.text_part.decoded).to include('Locked Operator')
      expect(mail.html_part.decoded).to include('Locked Operator')
    end

    it 'includes the access IP in the body' do
      expect(mail.text_part.decoded).to include('203.0.113.5')
      expect(mail.html_part.decoded).to include('203.0.113.5')
    end
  end
end
