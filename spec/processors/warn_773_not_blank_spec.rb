# frozen_string_literal: true

require 'spec_helper'

describe EresStats::Warn773NotBlank do
  let(:subject) { described_class.new(['allowed_773']) }

  context 'when result has a 773 that is not explicitly permitted' do
    let(:result) { make_result(coll_titles: 'other_773') }

    describe '#process' do
      it 'adds a note' do
        subject.process([result])
        expect(result.review).to eq(['773 not blank'])
      end
    end

    describe '#disallowed_773?' do
      it 'is true' do
        expect(subject.disallowed_773?(result)).to be true
      end
    end
  end

  context 'when result has a permitted 773' do
    let(:result) { make_result(coll_titles: 'allowed_773') }

    describe '#process' do
      it 'adds no notes' do
        subject.process([result])
        expect(result.review + result.remove).to be_empty
      end
    end

    describe '#disallowed_773?' do
      it 'is false' do
        expect(subject.disallowed_773?(result)).to be false
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

    describe '#disallowed_773?' do
      it 'is false' do
        expect(subject.disallowed_773?(result)).to be false
      end
    end
  end
end
