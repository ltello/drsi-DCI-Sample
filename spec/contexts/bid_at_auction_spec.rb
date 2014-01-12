require 'model_spec_helper'

describe BidAtAuction do

  let(:buy_it_now_price) {10000}
  let(:seller)           {User.create(password: 'seller1', password_confirmation: 'seller1', email: 'seller1@gmail.com', name: 'seller1')}
  let(:bidder)           {User.create(password: 'bidder1', password_confirmation: 'bidder1', email: 'bidder1@gmail.com', name: 'bidder1')}
  let(:another_bidder)   {User.create(password: 'bidder2', password_confirmation: 'bidder2', email: 'bidder2@gmail.com', name: 'bidder2')}
  let(:auction)          {make_auction(item_name: 'item1_name', item_description: 'item1_description')}
  let(:closed_auction)   {make_auction(item_name: 'item2_name', item_description: 'item2_description').tap(&:close)}

  describe "Calling" do

    context "BidAtAuction is the context used to add bids in an auction" do

      it "It has two roles (bidder and auction) you have to provide players for." do
        r = make_bid(:bidder => bidder, :auction => auction, :amount => 1000)
        r.should_not be_a(Exception)
        r.should be_a(Bid)
      end

      it "An :amount entry arg must also be provided..." do
        r = make_bid(:bidder => bidder, :auction => auction, :amount => nil)
        r.should be_a(BidAtAuction::ValidationException)
        r.errors.should include('Amount is not valid.')
      end
    end
  end


  describe "Validation" do

    it "The bid is not valid when the :amount is not a positive integer value..." do
      r = make_bid(:bidder => bidder, :auction => auction, :amount => :invalid)
      r.should be_a(BidAtAuction::ValidationException)
      r.errors.should include('Amount is not valid.')
    end

    it "... or the bidder is bidding against himself..." do
      make_bid(:bidder => bidder, :auction => auction, :amount => 777)
      make_bid(:bidder => bidder, :auction => auction, :amount => 900).errors.should include('Bidding against yourself is not allowed.')
    end

    it "... or when the amount of the last bid is the same..." do
      make_bid(:bidder => another_bidder, :auction => auction, :amount => 777)
      make_bid(:bidder => bidder, :auction => auction, :amount => 777).errors.should include('The amount must be greater than the last bid.')
    end

    it "... or when bidding on a closed auction" do
      auction.close
      make_bid.errors.should include('Bidding on closed auction is not allowed.')
    end
  end


  describe "Extending the auction" do

    it "Increases the auction's end date when the bid is made within the extending interval" do
      auction.start
      auction.end_date = Time.now + ExtendAuction::EXTENDING_INTERVAL - 1.minute
      ->{make_bid}.should change(auction, :end_date).by(ExtendAuction::EXTENDING_INTERVAL)
    end

    it "Does not extend when more time left" do
      auction.end_date = Time.now + ExtendAuction::EXTENDING_INTERVAL + 1.minute
      ->{make_bid}.should_not change(auction, :end_date)
    end

    it "Does not extend when auction is not started" do
      ->{make_bid(auction: closed_auction)}.should_not change(auction, :end_date)
    end
  end


  describe "Buying" do

    it "Does not allow a bid greater than the buy it now price..." do
      make_bid(amount: buy_it_now_price + 1).errors.should include('Bid cannot exceed the buy it now price.')
    end

    it "... but it does when the bid amount is exactly the buy it now price" do
      auction.should be_started
      r = make_bid(amount: buy_it_now_price)
      auction.winner.should eq(bidder)
      auction.should be_closed
      r.should be_a(Bid)
    end
  end


  private

  def make_bid options = {}
    amount  = options.fetch(:amount, 999)
    user    = options.fetch(:bidder, bidder)
    subasta = options.fetch(:auction, auction)
    BidAtAuction[:bidder => user, :auction => subasta, :amount => amount]
  end

  def make_auction(opts={})
    CreateAuction[seller:           opts.fetch(:seller,           seller),
                  item_name:        opts.fetch(:item_name,        'item_name'),
                  item_description: opts.fetch(:item_description, 'item1_description'),
                  end_date:         opts.fetch(:end_date,         (Time.now + 90.minutes)),
                  buy_it_now_price: opts.fetch(:buy_it_now_price, buy_it_now_price),
                  extendable:       opts.fetch(:extendable,       true)]
  end
end
