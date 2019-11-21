# frozen_string_literal: true

require 'spec_helper'

describe EresStats::Bad856x do
  let(:subject) { described_class.new }

  context 'when result has a 856 that is not permitted' do
    let(:result) { make_result(m856x: 'other_856x') }

    describe '#process' do
      it 'adds a note' do
        subject.process([result])
        expect(result.review).to eq(['856x'])
      end
    end

    describe '#bad_856x?' do
      it 'is true' do
        expect(subject.bad_856x?(result)).to be true
      end
    end
  end

  context 'when result has a permitted 856x' do
    let(:result) { make_result(m856x: 'ocalink_ldss') }

    describe '#process' do
      it 'adds no notes' do
        subject.process([result])
        expect(result.review + result.remove).to be_empty
      end
    end

    describe '#bad_856x?' do
      it 'is false' do
        expect(subject.bad_856x?(result)).to be false
      end
    end
  end

  context 'when result has no 856x' do
    let(:result) { make_result({}) }

    describe '#process' do
      it 'adds no notes' do
        subject.process([result])
        expect(result.review + result.remove).to be_empty
      end
    end

    describe '#bad_856x?' do
      it 'is false' do
        expect(subject.bad_856x?(result)).to be false
      end
    end
  end
end
