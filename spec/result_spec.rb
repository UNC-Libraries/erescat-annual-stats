# frozen_string_literal: true

require 'spec_helper'

describe EresStats::Result do
  let(:empty_result) { EresStats::Result.new }
  let(:result) do
    EresStats::Result.new(
      m919: '|aFilmFinder',
      url: 'http://example.com',
      mat_type: 'a',
      bib_locs: 'er, es',
      m856x: 'foo;;;bar',
      coll_titles: 'lorem;;;ipsum'
    )
  end

  describe 'initialization' do
    it 'sets m919' do
      expect(result.m919).to eq('|aFilmFinder')
    end

    it 'm919 defaults to empty string' do
      expect(empty_result.m919).to eq('')
    end

    it 'sets bib_locs as array of location strings' do
      expect(result.bib_locs).to eq(['er', 'es'])
    end

    it 'bib_locs defaults to empty array' do
      expect(empty_result.bib_locs).to eq([])
    end

    it 'sets m856x as array of 856x strings' do
      expect(result.m856x).to eq(['foo', 'bar'])
    end

    it 'm856x defaults to empty array' do
      expect(empty_result.m856x).to eq([])
    end

    it 'sets coll_titles as array of 773/collection strings' do
      expect(result.coll_titles).to eq(['lorem', 'ipsum'])
    end

    it 'coll_titles defaults to empty array' do
      expect(empty_result.coll_titles).to eq([])
    end
  end
end
