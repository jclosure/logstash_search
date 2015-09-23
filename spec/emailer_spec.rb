require 'emailer'

# https://github.com/rspec/rspec-expectations
# http://tutorials.jumpstartlab.com/topics/internal_testing/rspec_practices.html

RSpec.describe Emailer, "searching" do

  context 'when configured' do
    before :each do
      @config = Emailer.configure
    end
    it 'defaults dev environment' do
      expect(@config.name).to eq "development"
    end
    
    
  end

  context 'when there are results' do
    before :each do
      @config = Emailer.configure
    end
    it 'searches and returns output' do
      emailer = Emailer.new @config
      output = emailer.search
      expect(output.params).to be_truthy
      expect(output.config).to be_truthy
      expect(output.response).to be_truthy
    end
    it 'generates an html message' do

    end
    it 'generates data' do

    end
    it 'sends an email notification' do

    end
  end

end
