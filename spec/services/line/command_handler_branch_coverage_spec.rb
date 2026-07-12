# frozen_string_literal: true

require 'rails_helper'

# Supplements command_handler_spec.rb with the remaining conditional branches.
RSpec.describe Line::CommandHandler do
  let(:adapter) { instance_double(Line::ClientAdapter) }
  let(:handler) { described_class.new(adapter) }
  let(:group_id) { 'GROUP123' }

  describe '#handle_removal (branch coverage)' do
    it 'does nothing when the message is not the removal command' do
      event = double('event', message: double(text: 'just chatting'))

      expect { handler.handle_removal(event, group_id) }.not_to raise_error
    end

    it 'does nothing when the event has no message' do
      event = double('event', message: nil)

      expect { handler.handle_removal(event, group_id) }.not_to raise_error
    end

    it 'leaves the group when the source is a group' do
      allow(adapter).to receive(:leave_group)
      event = double('event',
                     message: double(text: described_class::REMOVAL_COMMAND),
                     source: double(group_id: group_id, room_id: nil))

      handler.handle_removal(event, group_id)

      expect(adapter).to have_received(:leave_group).with(group_id)
    end

    it 'leaves the room when the source is a room' do
      allow(adapter).to receive(:leave_room)
      event = double('event',
                     message: double(text: described_class::REMOVAL_COMMAND),
                     source: double(group_id: nil, room_id: 'ROOM123'))

      handler.handle_removal(event, group_id)

      expect(adapter).to have_received(:leave_room).with(group_id)
    end

    it 'does nothing when the source is neither a group nor a room' do
      event = double('event',
                     message: double(text: described_class::REMOVAL_COMMAND),
                     source: double(group_id: nil, room_id: nil))

      expect { handler.handle_removal(event, group_id) }.not_to raise_error
    end

    it 'does nothing when the removal command has no source' do
      event = double('event',
                     message: double(text: described_class::REMOVAL_COMMAND),
                     source: nil)

      expect { handler.handle_removal(event, group_id) }.not_to raise_error
    end
  end

  describe '#handle_span_setting (branch coverage)' do
    it 'returns early when the message has no text' do
      event = double('event', message: nil)

      expect { handler.handle_span_setting(event, group_id) }.not_to raise_error
    end

    it 'returns early when the group is not found' do
      event = double('event', message: double(text: described_class::SPAN_FASTER))

      expect { handler.handle_span_setting(event, 'UNKNOWN') }.not_to raise_error
    end

    it 'sends a confirmation even when the text matches no case clause' do
      # `span_command?` is stubbed true so the `case` falls through its whens,
      # exercising the implicit else branch.
      create(:line_group, line_group_id: group_id)
      allow(handler).to receive(:span_command?).and_return(true)
      allow(adapter).to receive(:push_message)
      event = double('event', message: double(text: 'UNMAPPED COMMAND'))

      handler.handle_span_setting(event, group_id)

      expect(adapter).to have_received(:push_message).with(group_id, hash_including(type: 'text'))
    end
  end
end
