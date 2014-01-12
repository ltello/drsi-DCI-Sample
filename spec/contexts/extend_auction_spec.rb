require 'model_spec_helper'

describe ExtendAuction do
  let(:buy_it_now_price) {10000}
  let(:seller)           {User.create(password: 'seller1', password_confirmation: 'seller1', email: 'seller1@gmail.com', name: 'seller1')}

  before(:each) do
    @auction = CreateAuction[seller: seller, item_name: 'item1_name', item_description: 'item1_description', end_date: (Time.now + 10.minutes), buy_it_now_price: buy_it_now_price, extendable: true]
  end

  context "Calling" do

    context "ExtendAuction is the context used to delay the end of an auction" do

      it "It has one role (auction) you have to provide a player for." do
        r = ExtendAuction[auction: @auction]
        r.should_not be_a(Exception)
        [true, false].should include(r)
      end
    end
  end


  context "Extending" do

    it "It does not extend the auction when it is not extendable..." do
      @auction.extendable = false
      @auction.save.should be_true
      ExtendAuction[auction: @auction].should be_false
    end

    it "... or when it is not started..." do
      @auction.close
      @auction.started?.should be_false
      ExtendAuction[auction: @auction].should be_false
    end

    it "... or when it's not near the end of the auction" do
      @auction.end_date = Time.now + ExtendAuction::EXTENDING_INTERVAL + 10.minutes
      ExtendAuction[auction: @auction].should be_false
    end

    it "It does extend the auction otherwise" do
      ->{ExtendAuction[auction: @auction].should be_true}.should change(@auction, :end_date).by(ExtendAuction::EXTENDING_INTERVAL)
    end

    it "If for some reason, errors occur when extending the auction, you get the messages in the exception object returned..." do
      @auction.buy_it_now_price = nil
      r = ExtendAuction[auction: @auction]
      r.should be_an(Exception)
      r.errors.should_not be_empty
    end
  end
end
