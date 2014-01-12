require 'model_spec_helper'

describe BidAtAuction do
  let(:bidder){User.new}
  let(:bids) {double('Bids')}
  let(:auction){double("Auction", buy_it_now_price: 999999, started?: true, end_date: Time.now + 1.day, bids: bids, extendable:true)}

  before :each do
    auction.stub(:last_bidder)
    auction.stub(:last_price)
    auction.stub(:can_be_extended?)
    auction.stub(:maybe_extend_end_date){auction.can_be_extended?}
    auction.stub(:last_bid){nil}
  end

  context "Bidding" do
    let(:amount){777}
    let(:the_bid){bid(bidder: bidder, amount: amount)}

    before :each do
      bids.stub(:create!){the_bid}
    end

    example do
      make_bid(amount: amount).is_a?(Bid)
    end
  end

  describe "Validations" do
    let(:another_bidder) {User.new}

    it "errors when no amount" do
      r = make_bid(amount: nil)
      r.should be_a(BidAtAuction::ValidationException)
      r.errors.should include('Amount is not valid.')
    end

    it "errors when an invalid amount" do
      make_bid(amount: :INVALID).errors.should include('Amount is not valid.')
    end

    it "errors when the bidder is bidding against himself" do
      amount = 777
      auction.stub(:last_bidder).and_return(bidder)
      make_bid(amount: amount).errors.should include('Bidding against yourself is not allowed.')
    end

    it "errors when the amount of the last bid is the same" do
      auction.stub(:last_price).and_return(777)
      make_bid(amount: 777).errors.should include('The amount must be greater than the last bid.')
    end

    it "errors when bidding on a closed auction" do
      auction.stub(started?: false)
      make_bid.errors.should include('Bidding on closed auction is not allowed.')
    end
  end

  describe "Extending the auction" do

    before :each do
      bids.stub(:create!){bid}
      auction.stub(:almost_closed?) {(auction.end_date - Time.now) < ExtendAuction::EXTENDING_INTERVAL}
    end

    it "increases the auction's end date when the bid is made within the extending interval" do
      auction.stub(end_date: Time.now + ExtendAuction::EXTENDING_INTERVAL - 1.minute)
      auction.stub(:end_date= =>  auction.end_date + ExtendAuction::EXTENDING_INTERVAL)
      auction.stub(:save! => true)
      auction.should_receive(:end_date=)
      auction.should_receive(:save!)
      make_bid
    end

    it "does not extend when more time left" do
      auction.stub(end_date: Time.now + ExtendAuction::EXTENDING_INTERVAL + 1.minute )
      auction.should_not_receive(:end_date=)
      make_bid
    end

    it "does not extend when auction is not started" do
      auction.stub(end_date: Time.now, started?: false)
      auction.should_not_receive(:maybe_extend_end_date)
      make_bid
    end
  end

  describe "Buying" do
    let(:buy_it_now_price) {777}
    let(:another_bidder){User.new}

    before do
      auction.stub(buy_it_now_price: buy_it_now_price)
    end

    it "notifies the listener when the bid greater than the buy it now price" do
      make_bid(amount: buy_it_now_price + 1).errors.should include('Bid cannot exceed the buy it now price.')
    end

    it "notifies the listener about the purchase" do
      bid = bid(amount: buy_it_now_price)
      bid.stub(:purchasing?){bid.amount == auction.buy_it_now_price}
      bids.stub(:create!){bid}
      auction.stub(:winner)
      auction.stub(:winner=)
      auction.stub(:winner=)
      auction.stub(:close)
      auction.stub(:status)
      auction.stub(:status=)
      make_bid(amount: buy_it_now_price).should be(bid)
    end
  end

  describe "Error handling" do
    it "notifies the listener when cannot make a bid" do
      bids.stub(:create!).and_raise(InvalidRecordException.new([:error]))
      make_bid.should be_a(InvalidRecordException)
    end
  end

  private

  def make_bid options = {}
    amount = options.fetch(:amount, 999)
    user   = options.fetch(:bidder, bidder)
    BidAtAuction[:bidder => user, :auction => auction, :amount => amount]
  end

  def bid options = {}
    stub(user:        options.fetch(:bidder, bidder),
         amount:      options.fetch(:amount, 999),
         purchasing?: options.fetch(:purchasing?, false))
  end
end
