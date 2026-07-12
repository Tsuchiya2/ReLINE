# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  it 'is defined as a module' do
    expect(described_class).to be_a(Module)
  end
end
