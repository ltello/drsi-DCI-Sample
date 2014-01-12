require 'model_spec_helper'

describe Auction do

  context "Checking Fields" do

    [:seller_id, :item_id, :end_date].each do |fieldname|
      it("When blank?, it adds an error on #{fieldname}") {should validate_presence_of(fieldname)}
    end

    [:buy_it_now_price].each do |fieldname|
      it("adds an error on #{fieldname} when value is not numeric") {should validate_numericality_of(fieldname)}
    end
    #it {should ensure_inclusion_of(:status).in_array(['pending', 'started', 'closed', 'canceled'])}
  end

  let(:seller)         {ObjectMother.create_user}
  let(:end_date)       {DateTime.current + 1.day}
  let(:item)           {Item.create name: "Item"}
  let(:creation_attrs) {{seller: seller, item: item, buy_it_now_price: 10, extendable: true, end_date: end_date}}

  context "Creating a new auction" do
    let(:auction) {Auction.create(creation_attrs)}

    it "When given good params, a new auction is created and persisted..." do
      ->{Auction.create(creation_attrs)}.should change(Auction, :count).by(1)
    end

    it "... in pending status and with right fields values:" do
      auction.status.should == Auction::PENDING
    end

    it "... #seller,"           do auction.seller.should           == seller   end
    it "... #buy_it_now_price," do auction.buy_it_now_price.should == 10       end
    it "... #item,"             do auction.item.should             == item     end
    it "... #end_date,"         do auction.end_date.should         == end_date end
    it "... #extendable,"       do auction.extendable.should       be_true     end
    it "... #bids,"             do auction.bids.should             be_empty    end
    it "... #last_bid,"         do auction.last_bid.should         be_blank    end
    it "... #last_bidder,"      do auction.last_bidder.should      be_blank    end
    it "... and #last_price."   do auction.last_price.should       be_blank    end

    it "Past end dates are not allowed..." do
      auction = Auction.create(creation_attrs.merge(end_date: (Time.now - 1.second)))
      auction.should_not be_persisted
      auction.should have(1).errors_on(:end_date)
    end
  end


  describe "Auction started" do
    let(:auction) {Auction.create(creation_attrs)}

    it "A just created auction must not be started..." do
      auction.started?.should be_false
    end

    it "You have to explicitly call #start to start an auction" do
      auction.start
      auction.reload.status.should == Auction::STARTED
      auction.started?.should be_true
    end
  end


  describe "Auction expired" do
    let(:auction) {Auction.create(creation_attrs).tap {|a| a.start}}

    it "A just created auction must not be expired..." do
      auction.expired?.should be_false
    end

    it "When the time is prior to the end date of an auction, it must not be expired." do
      auction.expired?.should be_false
    end

    it "Only when an auction is started and its end date is past, the auction is expired" do
      auction.end_date = Time.now - 1.second
      auction.expired?.should be_true
    end
  end


  describe "Auction closed" do
    let(:auction) {Auction.create(creation_attrs)}

    it "A just created auction must not be closed..." do
      auction.closed?.should be_false
    end

    it "You have to explicitly call #close to close an auction" do
      auction.close
      auction.reload.status.should == Auction::CLOSED
      auction.closed?.should be_true
    end
  end


  describe "Auction bids" do
    let(:auction) {Auction.create!(creation_attrs)}
    let(:bidder)  {ObjectMother.create_user(email: "bidder@example.com")}

    it "A just created auction have no bids,..." do
      auction.bids.should be_empty
    end

    it "... so last bid, last_bidder and last_price are all nil..." do
      auction.last_bid.should    be_blank
      auction.last_bidder.should be_blank
      auction.last_price.should  be_blank
    end

    it "After a new bid is made, last bid, last_bidder and last_price refer all to that bid." do
      lambda do
        bid = auction.bids.create(user: bidder, amount:5)
        auction.last_bid.should == bid
      end.should change(Bid, :count).by(1)
      auction.last_bidder.should == bidder
      auction.last_price.should == 5
    end
  end


  describe "Assigning winner" do
    let(:auction) {Auction.create!(creation_attrs)}
    let(:bidder)  {ObjectMother.create_user(email: "bidder@example.com")}

    it "A just created auction have no (winner)." do
      auction.winner.should be_blank
    end

    it "When assigned, the winner cannot be the seller" do
      auction.winner = auction.seller
      auction.save.should be_false
      auction.should have_at_least(1).error_on(:winner)
      auction.winner = bidder
      auction.save.should be_true
      auction.should have(:no).errors
    end
  end

end
