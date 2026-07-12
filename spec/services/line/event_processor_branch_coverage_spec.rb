# frozen_string_literal: true

require 'rails_helper'

# Supplements event_processor_spec.rb with the remaining conditional branches:
# an unknown event type, a nil event source, and processed-set trimming.
RSpec.describe Line::EventProcessor do
  let(:adapter) { instance_double(Line::ClientAdapter) }
  let(:member_counter) { instance_double(Line::MemberCounter) }
  let(:group_service) { instance_double(Line::GroupService) }
  let(:command_handler) { instance_double(Line::CommandHandler) }
  let(:one_on_one_handler) { instance_double(Line::OneOnOneHandler) }

  let(:processor) do
    described_class.new(
      adapter: adapter,
      member_counter: member_counter,
      group_service: group_service,
      command_handler: command_handler,
      one_on_one_handler: one_on_one_handler
    )
  end

  before do
    stub_line_credentials
    stub_const('Line::Bot::Event::Message', Class.new)
    stub_const('Line::Bot::Event::Join', Class.new)
    stub_const('Line::Bot::Event::Leave', Class.new)
    stub_const('Line::Bot::Event::MemberJoined', Class.new)
    stub_const('Line::Bot::Event::MemberLeft', Class.new)

    allow(member_counter).to receive(:count).and_return(3)
    allow(PrometheusMetrics).to receive(:track_webhook_duration)
    allow(PrometheusMetrics).to receive(:track_event_success)
  end

  def none_match(event)
    [Line::Bot::Event::Message, Line::Bot::Event::Join, Line::Bot::Event::MemberJoined,
     Line::Bot::Event::Leave, Line::Bot::Event::MemberLeft].each do |klass|
      allow(klass).to receive(:===).with(event).and_return(false)
    end
  end

  it 'processes an unknown event type with a nil source without dispatching to a handler' do
    unknown_event = double('Unknown Event', class: Object, timestamp: 12_345, source: nil, message: nil)
    none_match(unknown_event)

    expect { processor.process([unknown_event]) }.not_to raise_error

    expect(PrometheusMetrics).to have_received(:track_event_success).with(unknown_event)
  end

  it 'trims the processed-events set once it exceeds the size limit' do
    message_event = double('Message Event', class: Line::Bot::Event::Message, timestamp: 999,
                                            source: double(group_id: 'GROUP123', room_id: nil),
                                            message: double(id: 'MSG1', text: 'hi'))
    allow(Line::Bot::Event::Message).to receive(:===).with(message_event).and_return(true)
    [Line::Bot::Event::Join, Line::Bot::Event::MemberJoined, Line::Bot::Event::Leave,
     Line::Bot::Event::MemberLeft].each do |klass|
      allow(klass).to receive(:===).with(message_event).and_return(false)
    end
    allow(command_handler).to receive(:handle_removal)
    allow(command_handler).to receive(:handle_span_setting)
    allow(group_service).to receive(:update_record)

    oversized = Set.new((0..10_000).map(&:to_s))
    processor.instance_variable_set(:@processed_events, oversized)

    processor.process([message_event])

    expect(oversized).not_to include('0') # first element was evicted
    expect(group_service).to have_received(:update_record).with('GROUP123', 3)
  end
end
