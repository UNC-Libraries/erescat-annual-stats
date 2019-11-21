# frozen_string_literal: true

require 'spec_helper'

describe EresStats::AllowOnlyMatType do
  let(:subject) { described_class.new(['a', 'b']) }

  context 'when result has a disallowed material type' do
    let(:result) { make_result(mat_type: 'c') }

    describe '#process' do
      it 'adds a note' do
        subject.process([result])
        expect(result.review).to eq(['Check material type'])
      end
    end

    describe '#allowed_mat_type?' do
      it 'is false' do
        expect(subject.allowed_mat_type?(result)).to be false
      end
    end
  end

  context 'when result has an allowed material type' do
    let(:result) { make_result(mat_type: 'b') }

    describe '#process' do
      it 'adds no notes' do
        subject.process([result])
        expect(result.review + result.remove).to be_empty
      end
    end

    describe '#allowed_mat_type?' do
      it 'is false' do
        expect(subject.allowed_mat_type?(result)).to be true
      end
    end
  end
end
