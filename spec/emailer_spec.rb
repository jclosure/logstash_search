require 'emailer'

# https://github.com/rspec/rspec-expectations

RSpec.describe Emailer, "searching" do

  context 'when it gets configured' do
    it 'defaults config to dev' do
      @config = Emailer.configure
      expect(@config.name).to eq "development"
    end
  end

  context 'when there are results' do
    it 'searches' do
      binding.pry
      emailer = Emailer.new @config
      output = emailer.search
      expect(output.params).to be_truthy
      expect(output.config).to be_truthy
      expect(output.response).to be_truthy
    end
    it 'generates an html message' do

    end
    it 'sends an email notification' do

    end
  end

end
