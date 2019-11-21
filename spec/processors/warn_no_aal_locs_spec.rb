# frozen_string_literal: true

require 'spec_helper'

describe EresStats::WarnNoAALLocs do
  let(:subject) { described_class.new }

  context 'when an AAL loc is present' do
    let(:result) { make_result(bib_locs: 'noh, er') }

    describe '#aal_locs?' do
      it 'is true' do
        expect(subject.aal_locs?(result)).to be true
      end
    end

    describe '#process' do
      it 'adds no notes' do
        subject.process([result])
        expect(result.review + result.remove).to be_empty
      end
    end
  end

  context 'when no AAL loc is present' do
    let(:k) { make_result(bib_locs: 'noh') }
    let(:noh) { make_result(bib_locs: 'k') }

    describe '#aal_locs?' do
      it 'is false', :aggregate_results do
        expect(subject.aal_locs?(k)).to be false
        expect(subject.aal_locs?(noh)).to be false
      end
    end

    describe '#process' do
      it 'adds a review note', :aggregate_results do
        subject.process([k, noh])
        expect(k.review).to include('Check location')
        expect(noh.remove).to include('No AAL location')
      end

      it 'adds a remove note', :aggregate_results do
        subject.process([k, noh])
        expect(k.remove).to include('No AAL location')
        expect(noh.remove).to include('No AAL location')
      end
    end
  end
end
