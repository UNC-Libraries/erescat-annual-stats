# frozen_string_literal: true

require 'spec_helper'

describe EresStats::RequireAllLocations do
  let(:subject) { described_class.new(['foo', 'bar']) }

  context 'when an all required locations are present' do
    let(:result) { make_result(bib_locs: 'bar, foo') }

    describe '#locations_lacking' do
      it 'returns empty array' do
        expect(subject.locations_lacking(result)).to be_empty
      end
    end

    describe '#process' do
      it 'adds no notes' do
        subject.process([result])
        expect(result.review + result.remove).to be_empty
      end
    end
  end

  context 'when one or more required locations are lacking' do
    let(:result) { make_result(bib_locs: 'bar, baz') }

    describe '#locations_lacking' do
      it 'returns array of lacking locations' do
        expect(subject.locations_lacking(result)).to eq(['foo'])
      end
    end

    describe '#process' do
      it 'adds review note(s) indicating missing location(s)' do
        subject.process([result])
        expect(result.review).to eq ['Missing foo location']
      end
    end
  end
end
