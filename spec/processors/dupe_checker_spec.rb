# frozen_string_literal: true

require 'spec_helper'

describe EresStats::DupeChecker do
  let(:subject) { described_class.new }

  describe '#process' do
    let(:result) { make_result(best_title_norm: 'some title') }

    it '#sets titlematch' do
      subject.process([result])
      expect(result.titlematch).to eq('some title')
    end
  end

  describe '#mark_dupes' do
    let(:results) do
      [
        make_result(best_title_norm: 'no dupe'),
        make_result(best_title_norm: 'dupe'),
        make_result(best_title_norm: 'dupe'),
        make_result(best_title_norm: 'dupe')
      ]
    end

    it 'nothing for titles with no dupes' do
      subject.process(results)
      expect(results.first.output(['PossibleDupe']).first).to be_empty
    end

    it 'marks one record in each dupe set as Dupe0' do
      subject.process(results)
      expect(results[1].output(['PossibleDupe']).first).to eq('Dupe0')
    end

    it 'marks remaining records in each dupe set as DupeX', :aggregate_failures do
      subject.process(results)
      expect(results[2].output(['PossibleDupe']).first).to eq('DupeX')
      expect(results[3].output(['PossibleDupe']).first).to eq('DupeX')
    end
  end
end
