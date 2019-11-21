# frozen_string_literal: true

require 'spec_helper'

describe EresStats::FlagESRI do
  let(:subject) { described_class.new }

  context 'when result has an ESRI 919' do
    let(:result) { make_result(m919: '|aEsriDataSETS') }

    describe '#process' do
      it 'adds a remove note' do
        subject.process([result])
        expect(result.remove.first).to match(/Do not count/)
      end
    end

    describe '#esri?' do
      it 'is true' do
        expect(subject.esri?(result)).to be true
      end
    end
  end

  context 'when result lacks an ESRI 919' do
    let(:result) { make_result(m919: '|aFilmfinder') }

    describe '#process' do
      it 'adds no notes' do
        subject.process([result])
        expect(result.review + result.remove).to be_empty
      end
    end

    describe '#esri?' do
      it 'is false' do
        expect(subject.esri?(result)).to be false
      end
    end
  end
end
