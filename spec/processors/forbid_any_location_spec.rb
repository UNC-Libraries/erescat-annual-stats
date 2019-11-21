# frozen_string_literal: true

require 'spec_helper'

describe EresStats::ForbidAnyLocation do
  let(:subject) { described_class.new(['foo', 'bar']) }

  context 'when result has one or more forbidden location' do
    let(:result) { make_result(bib_locs: 'baz, foo') }

    describe '#process' do
      it 'adds a note' do
        subject.process([result])
        expect(result.review).to eq(['foo location'])
      end
    end

    describe '#forbidden_locs' do
      it 'returns array of problem 773s' do
        expect(subject.forbidden_locs(result)).to eq(
          ['foo']
        )
      end
    end
  end

  context 'when result has no forbidden locations' do
    let(:result) { make_result(bib_locs: 'baz') }

    describe '#process' do
      it 'adds no notes' do
        subject.process([result])
        expect(result.review + result.remove).to be_empty
      end
    end

    describe 'forbidden_locs' do
      it 'is false' do
        expect(subject.forbidden_locs(result)).to be_empty
      end
    end
  end
end
