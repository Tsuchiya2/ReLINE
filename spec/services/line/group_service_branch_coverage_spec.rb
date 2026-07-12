# frozen_string_literal: true

require 'rails_helper'

# Supplements group_service_spec.rb with the remaining branch.
RSpec.describe Line::GroupService do
  let(:adapter) { instance_double(Line::ClientAdapter) }
  let(:service) { described_class.new(adapter) }

  describe '#send_welcome_message' do
    it 'enqueues a nil message when the message type is unknown' do
      allow(Line::WelcomeMessageJob).to receive(:perform_later)

      service.send_welcome_message('GROUP123', message_type: :unexpected)

      expect(Line::WelcomeMessageJob).to have_received(:perform_later).with('GROUP123', nil)
    end
  end
end
