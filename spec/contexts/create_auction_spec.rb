require 'model_spec_helper'

describe CreateAuction do

  let(:buy_it_now_price)     {10000}
  let(:seller)               {User.create(password: 'seller1', password_confirmation: 'seller1', email: 'seller1@gmail.com', name: 'seller1')}
  let(:item_params)          {{item_name:'item1_name', item_description:'item1_description'}}
  let(:end_date)             {Time.now + 90.minutes}
  let(:no_extendable_params) {item_params.merge(buy_it_now_price: buy_it_now_price, end_date: end_date, extendable: true)}
  let(:all_auction_params)   {no_extendable_params.merge(extendable: true)}

  describe "Calling" do

    context "CreateAuction is the context used to create and start new auctions" do

      it "It has only one role (seller) you have to provide a player for." do
        r = create_auction(item_params.merge(buy_it_now_price: buy_it_now_price, end_date: end_date))
        r.should_not be_a(Exception)
        r.should be_an(Auction)
      end

      it "... :item_name, :end_date and :buy_it_now_price entry args must also be provided..." do
        r = create_auction(buy_it_now_price: buy_it_now_price, end_date: end_date)
        r.should be_a(InvalidRecordException)
        r.errors.should include("Name can't be blank")
        r = create_auction(item_params.merge(end_date: end_date))
        r.should be_a(InvalidRecordException)
        r.errors.should include('Buy it now price is not a number')
        r = create_auction(item_params.merge(buy_it_now_price: buy_it_now_price))
        r.should be_a(InvalidRecordException)
        r.errors.should include("End date can't be blank")
      end

      it "... and :item_description and :extendable entry args are optional." do
        r = create_auction(no_extendable_params)
        r.should_not be_a(InvalidRecordException)
        r.should be_an(Auction)
      end
    end
  end

  describe "Successful creation" do

    it "The result of calling this context is the creation of new item instance..." do
      ->{create_auction(all_auction_params)}.should change(Item, :count).by(1)
    end

    it "... with the given item values as fields" do
      create_auction(all_auction_params)
      new_item = Item.last
      [new_item.name, new_item.description].should == item_params.values_at(:item_name, :item_description)
    end

    it "Of course, it also creates a new auction instance..." do
      ->{create_auction(all_auction_params)}.should change(Auction, :count).by(1)
    end

    it "... with the given args as fields" do
      auction = create_auction(all_auction_params)
      [auction.item.name, auction.item.description].should == item_params.values_at(:item_name, :item_description)
      [auction.seller, auction.item.name, auction.item.description, auction.buy_it_now_price, auction.end_date, auction.extendable].should == [seller, *all_auction_params.values]
    end

    it "Moreover, it also starts the recently created auction" do
      create_auction(all_auction_params).should be_started
    end
  end


  describe "Error handling" do

    it "If for some reason, errors occur when creating the auction, you get the messages in the exception object returned..." do
      r = create_auction(end_date: end_date)
      r.should be_an(InvalidRecordException)
      r.errors.should_not be_blank
    end

    it "... and no item should have been created." do
      ->{create_auction(end_date: end_date)}.should_not change(Item, :count)
    end
  end

  private

  def create_auction(opts={})
    CreateAuction[{seller: seller}.merge!(opts)]
  end
end
