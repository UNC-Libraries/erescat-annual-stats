# frozen_string_literal: true

require 'spec_helper'

describe EresStats::Warn856uBlank do
  let(:subject) { described_class.new }

  context 'when result lacks a URL' do
    let(:result) { make_result({}) }

    describe '#process', :aggregate_failures do
      it 'adds a remove note' do
        subject.process([result])
        expect(result.review).to eq(['No URL'])
        expect(result.review).to eq(['No URL'])
      end
    end

    describe '#m856u?' do
      it 'is false' do
        expect(subject.m856u?(result)).to be false
      end
    end
  end

  context 'when result has a URL' do
    let(:result) { make_result(url: 'http://archive.org') }

    describe '#process' do
      it 'adds no notes' do
        subject.process([result])
        expect(result.review + result.remove).to be_empty
      end
    end

    describe '#m856u?' do
      it 'is true' do
        expect(subject.m856u?(result)).to be true
      end
    end
  end
end
