require 'model_spec_helper'

describe CloseAuction do
  let(:buy_it_now_price) {10000}
  let(:seller)           {User.create(password: 'seller1', password_confirmation: 'seller1', email: 'seller1@gmail.com', name: 'seller1')}
  let(:bidder)           {User.create(password: 'bidder1', password_confirmation: 'bidder1', email: 'bidder1@gmail.com', name: 'bidder1')}
  let(:another_bidder)   {User.create(password: 'bidder2', password_confirmation: 'bidder2', email: 'bidder2@gmail.com', name: 'bidder2')}

  before(:each) do
    @auction = CreateAuction[seller: seller, item_name: 'item1_name', item_description: 'item1_description', end_date: (Time.now + 90.minutes), buy_it_now_price: buy_it_now_price, extendable: true]
  end

  context "Calling" do

    context "CloseAuction is the context used to finish an auction" do

      it "It has one role (auction) you have to provide a player for." do
        r = CloseAuction[auction: @auction]
        r.should_not be_a(Exception)
        [true, false].should include(r)
      end
    end
  end


  context "Assigning winner" do

    it "It closes an auction with no winner if it has no bids..." do
      @auction.started?.should be_true
      @auction.bids.count.should be(0)
      @auction.last_bidder.should be_blank
      @auction.winner = bidder
      @auction.save.should be_true
      CloseAuction[auction: @auction].should be_true
      @auction.winner.should be_blank
      @auction.closed?.should be_true
    end

    it "... or with last bidder as the winner if it has bids" do
      BidAtAuction[:bidder => another_bidder, :auction => @auction, :amount => 500]
      BidAtAuction[:bidder => bidder,         :auction => @auction, :amount => 1000]
      @auction.bids.count.should be(2)
      @auction.last_bidder.should eq(bidder)
      @auction.winner.should be_blank
      CloseAuction[auction: @auction]
      @auction.winner.should eq(bidder)
      @auction.closed?.should be_true
    end

    it "If for some reason, errors occur when closing the auction, you get the messages in the exception object returned..." do
      @auction.end_date = Time.now - 1.minute
      r = CloseAuction[auction: @auction]
      r.should be_an(Exception)
      r.errors.should_not be_empty
    end

    it "... and winner and status of the auction should be as they were before the error." do
      previous_winner_id = @auction.winner_id
      previous_status    = @auction.status
      @auction.end_date = Time.now - 1.minute
      CloseAuction[auction: @auction]
      @auction.winner_id.should be(previous_winner_id)
      @auction.status.should be(previous_status)
    end
  end
end
