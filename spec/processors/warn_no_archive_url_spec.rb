# frozen_string_literal: true

require 'spec_helper'

describe EresStats::WarnNoArchiveURL do
  let(:subject) { described_class.new }

  context 'when result lacks an archive.org URL' do
    let(:result) { make_result(url: 'http://example.com') }

    describe '#process' do
      it 'adds a remove note' do
        subject.process([result])
        expect(result.review).to eq(['no archive.org URL'])
      end
    end

    describe '#archive_url?' do
      it 'is false' do
        expect(subject.archive_url?(result)).to be false
      end
    end
  end

  context 'when result has an archive.org URL' do
    let(:result) { make_result(url: 'http://archive.org') }

    describe '#process' do
      it 'adds no notes' do
        subject.process([result])
        expect(result.review + result.remove).to be_empty
      end
    end

    describe '#archive_url?' do
      it 'is true' do
        expect(subject.archive_url?(result)).to be true
      end
    end
  end
end
