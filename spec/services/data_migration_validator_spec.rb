# frozen_string_literal: true

require 'rails_helper'

# The Operator table no longer has the legacy `crypted_password` column, so these
# specs drive the validator through doubles/stubs instead of real ActiveRecord
# queries. This keeps the migration tooling covered without depending on a schema
# that has since been removed.
RSpec.describe DataMigrationValidator do
  describe '.generate_checksum' do
    let(:model_class) do
      instance_double(ActiveRecord::Relation).tap do |model|
        allow(model).to receive(:pluck)
          .with(:id, :email, :crypted_password, :password_digest)
          .and_return(records)
      end
    end

    let(:records) do
      [
        [1, 'a@example.com', nil, 'digest1'],
        [2, 'b@example.com', nil, 'digest2']
      ]
    end

    it 'returns one checksum per record' do
      expect(described_class.generate_checksum(model_class).size).to eq(2)
    end

    it 'returns SHA256 hex digests' do
      expect(described_class.generate_checksum(model_class)).to all(match(/\A[a-f0-9]{64}\z/))
    end

    it 'is deterministic for identical data' do
      first = described_class.generate_checksum(model_class)
      second = described_class.generate_checksum(model_class)
      expect(first).to eq(second)
    end

    it 'produces different checksums when the underlying data differs' do
      other = instance_double(ActiveRecord::Relation)
      allow(other).to receive(:pluck)
        .with(:id, :email, :crypted_password, :password_digest)
        .and_return([[1, 'a@example.com', nil, 'CHANGED']])

      expect(described_class.generate_checksum(model_class))
        .not_to eq(described_class.generate_checksum(other))
    end
  end

  describe '.validate_migration' do
    let(:before_checksums) { %w[abc123 def456 ghi789] }

    it 'returns true when checksums are identical' do
      expect(described_class.validate_migration(before_checksums, before_checksums.dup)).to be true
    end

    it 'returns true when the order changes but the data is the same' do
      expect(described_class.validate_migration(before_checksums, %w[ghi789 abc123 def456])).to be true
    end

    it 'raises when records are lost' do
      expect { described_class.validate_migration(before_checksums, %w[abc123 def456]) }
        .to raise_error(RuntimeError, 'Migration validation failed: 1 records lost')
    end

    it 'raises when unexpected records are added' do
      expect { described_class.validate_migration(before_checksums, %w[abc123 def456 ghi789 jkl012]) }
        .to raise_error(RuntimeError, 'Migration validation failed: 1 unexpected records added')
    end

    it 'raises when records are modified but the count is unchanged' do
      expect { described_class.validate_migration(before_checksums, %w[abc123 def456 xyz999]) }
        .to raise_error(RuntimeError, /Migration validation failed: \d+ records modified or corrupted/)
    end
  end

  describe '.verify_integrity' do
    let(:model_class) { class_double(Operator) }
    let(:missing_relation) { instance_double(ActiveRecord::Relation, count: missing_auth) }
    let(:duplicate_relation) { instance_double(ActiveRecord::Relation, count: duplicate_auth) }

    before do
      allow(model_class).to receive(:count).and_return(total)
      allow(model_class).to receive(:where)
        .with('crypted_password IS NULL AND password_digest IS NULL')
        .and_return(missing_relation)
      allow(model_class).to receive(:where)
        .with('crypted_password IS NOT NULL AND password_digest IS NOT NULL')
        .and_return(duplicate_relation)
    end

    context 'when there are no integrity issues' do
      let(:total) { 5 }
      let(:missing_auth) { 0 }
      let(:duplicate_auth) { 0 }

      it 'reports a valid result' do
        result = described_class.verify_integrity(model_class)
        expect(result).to eq(valid: true, total_records: 5, issues: [])
      end
    end

    context 'when records are missing authentication data' do
      let(:total) { 3 }
      let(:missing_auth) { 2 }
      let(:duplicate_auth) { 0 }

      it 'reports the missing authentication data issue' do
        result = described_class.verify_integrity(model_class)
        expect(result[:valid]).to be false
        expect(result[:issues]).to include('2 records missing authentication data')
      end
    end

    context 'when records have both authentication methods' do
      let(:total) { 3 }
      let(:missing_auth) { 0 }
      let(:duplicate_auth) { 1 }

      it 'reports the duplicate authentication issue' do
        result = described_class.verify_integrity(model_class)
        expect(result[:valid]).to be false
        expect(result[:issues]).to include('1 records have both crypted_password and password_digest')
      end
    end
  end

  describe '.validate_password_migration' do
    let(:scoped) { instance_double(ActiveRecord::Relation) }
    let(:where_chain) { instance_double(ActiveRecord::QueryMethods::WhereChain) }
    let(:not_migrated) { instance_double(ActiveRecord::Relation, count: missing) }

    before do
      allow(Operator).to receive(:where).with(password_digest: nil).and_return(scoped)
      allow(scoped).to receive(:where).and_return(where_chain)
      allow(where_chain).to receive(:not).with(crypted_password: nil).and_return(not_migrated)
    end

    context 'when every operator has a password_digest' do
      let(:missing) { 0 }

      it 'returns true' do
        expect(described_class.validate_password_migration).to be true
      end
    end

    context 'when some operators are missing a password_digest' do
      let(:missing) { 2 }

      it 'raises with the missing count' do
        expect { described_class.validate_password_migration }
          .to raise_error(RuntimeError, 'Migration incomplete: 2 operators missing password_digest')
      end
    end
  end
end
