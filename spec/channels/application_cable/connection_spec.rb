# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  it 'inherits from ActionCable::Connection::Base' do
    expect(described_class.ancestors).to include(ActionCable::Connection::Base)
  end
end
