# frozen_string_literal: true

require 'spec_helper'

describe EresStats::Warn773EstablishedColl do
  let(:subject) { described_class.new }

  context 'when result has a 773 for an established collection' do
    let(:result) { make_result(coll_titles: 'foo (online collection)') }

    describe '#process' do
      it 'adds a note' do
        subject.process([result])
        expect(result.review).to eq(['Dupe: foo (online collection)'])
      end
    end

    describe '#established_773s' do
      it 'returns array of problem 773s' do
        expect(subject.established_773s(result)).to eq(
          ['foo (online collection)']
        )
      end
    end
  end

  context 'when result has a non-established 773' do
    let(:result) { make_result(coll_titles: 'foobar') }

    describe '#process' do
      it 'adds no notes' do
        subject.process([result])
        expect(result.review + result.remove).to be_empty
      end
    end

    describe '#established_773s' do
      it 'is false' do
        expect(subject.established_773s(result)).to be_empty
      end
    end
  end

  context 'when result has no 773' do
    let(:result) { make_result({}) }

    describe '#process' do
      it 'adds no notes' do
        subject.process([result])
        expect(result.review + result.remove).to be_empty
      end
    end

    describe '#established_773s' do
      it 'is false' do
        expect(subject.established_773s(result)).to be_empty
      end
    end
  end
end
