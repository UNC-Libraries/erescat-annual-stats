# frozen_string_literal: true

require 'spec_helper'

describe EresStats::WarnNoFilmfinder do
  let(:subject) { described_class.new }

  context 'when result has a filmfinder 919' do
    let(:result) { make_result(bib_locs: 'noh', m919: '|aFilmfinder') }

    describe '#filmfinder?' do
      it 'is true' do
        expect(subject.filmfinder?(result)).to be true
      end
    end

    describe '#process' do
      it 'adds no notes' do
        subject.process([result])
        expect(result.review + result.remove).to be_empty
      end
    end
  end

  context 'when record includes a bib_loc of `ul`' do
    let(:result) { make_result(bib_locs: 'noh, ul', m919: '|anothing') }

    describe '#filmfinder?' do
      it 'is true' do
        expect(subject.filmfinder?(result)).to be true
      end
    end

    describe '#process' do
      it 'adds no review note' do
        subject.process([result])
        expect(result.review).to be_empty
      end
    end
  end

  context 'when result has no filmfinder 919 or filmfinder bib_loc' do
    let(:result) { make_result(bib_locs: 'noh', m919: '|anothing') }

    describe '#filmfinder?' do
      it 'is false' do
        expect(subject.filmfinder?(result)).to be false
      end
    end

    describe '#process' do
      it 'adds a review note' do
        subject.process([result])
        expect(result.review).to include('No filmfinder scope')
      end
    end
  end
end
