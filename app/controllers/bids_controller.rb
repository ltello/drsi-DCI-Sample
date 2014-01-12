class BidsController < ApplicationController
  attr_accessor :auction

  before_filter :authenticate_user!
  before_filter :find_auction, :only => [:create, :buy]


  def create
    result = do_bid(bid_params[:amount])
    result.errors.blank? ? bid_created_response! : no_bid_created_response!(result.errors)
  end

  def buy
    result = do_bid(auction.buy_it_now_price)
    result.errors.blank? ? buy_made_response! : no_bid_created_response!(result.errors)
  end


  private

    def bid_params
      p = {auction_id: params[:auction_id]}
      p.merge!(params[:bid_params]) if params[:bid_params]
      BidParams.new(p).attributes
    end

    def do_bid(amount)
      BidAtAuction[:bidder => current_user, :auction => auction, :amount => amount.to_i]
    end

    def bid_created_response!
      flash[:notice] = "Your bid is accepted."
      redirect_to auction_path(auction.id)
    end

    def buy_made_response!
      flash[:notice] = "Purchased successfully performed."
      redirect_to auction_path(auction.id)
    end

    def no_bid_created_response!(errors)
      flash[:error] = errors.join("\n")
      redirect_to auction_path(auction.id)
    end

  # Filters
    def find_auction
      self.auction = Auction.find(params[:auction_id])
      redirect_to(:back) unless auction
    end
end
