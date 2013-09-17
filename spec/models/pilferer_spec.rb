require 'spec_helper'

describe Pilferer do

  subject { described_class.new("http://www.example.com") }

  let(:dumby_noko_result)  { Object.new }
  let(:dumby_attributes)   { { 'src' => OpenStruct.new(value: test_image_source) } }
  let(:test_image_source)  { "http://foo.bar" }

  before do
    stub(dumby_noko_result).attributes { dumby_attributes }
  end

  describe '#sources' do
    context 'given an array of nokogiri elements' do
      it 'returns an array of image urls' do
        expect(subject.sources([dumby_noko_result])).to eq [test_image_source]
      end
    end
  end
end
