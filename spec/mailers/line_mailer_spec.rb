# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LineMailer, type: :mailer do
  before do
    # ApplicationMailer resolves the recipient from credentials, which are not
    # decryptable without the master key. Stub only the operator entry so the
    # rest of the credentials object stays intact for view/URL rendering.
    allow(Rails.application.credentials).to receive(:operator).and_return(email: 'operator@example.com')
  end

  describe '#error_email' do
    let(:mail) { described_class.error_email('GROUP123', 'Something failed') }

    it 'sets the subject' do
      expect(mail.subject).to eq('【Error通知】LINEとの通信において')
    end

    it 'delivers to the operator address from credentials' do
      expect(mail.to).to eq(['operator@example.com'])
    end

    it 'sends from the default address' do
      expect(mail.from).to eq(['from@example.com'])
    end

    it 'includes the group id in the body' do
      expect(mail.text_part.decoded).to include('GROUP123')
      expect(mail.html_part.decoded).to include('GROUP123')
    end

    it 'includes the error message in the body' do
      expect(mail.text_part.decoded).to include('Something failed')
      expect(mail.html_part.decoded).to include('Something failed')
    end
  end
end
