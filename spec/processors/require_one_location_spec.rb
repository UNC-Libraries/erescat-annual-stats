# frozen_string_literal: true

require 'spec_helper'

describe EresStats::RequireOneLocation do
  let(:subject) { described_class.new(['foo', 'bar']) }

  context 'when result has none of the required locations' do
    let(:result) { make_result(bib_locs: 'baz') }

    describe '#process' do
      it 'adds a note' do
        subject.process([result])
        expect(result.review).to eq(['baz contains 0 required locations'])
      end
    end

    describe '#any_required_loc?' do
      it 'is false' do
        expect(subject.any_required_loc?(result)).to be false
      end
    end
  end

  context 'when result has one or more required location' do
    let(:result) { make_result(bib_locs: 'baz, foo') }

    describe '#process' do
      it 'adds no notes' do
        subject.process([result])
        expect(result.review + result.remove).to be_empty
      end
    end

    describe '#any_required_loc?' do
      it 'is true' do
        expect(subject.any_required_loc?(result)).to be true
      end
    end
  end
end
