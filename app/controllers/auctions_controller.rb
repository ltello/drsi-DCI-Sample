class AuctionsController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :show]

  def index
    @auctions = AuctionsPresenter.new(Auction.all, current_user, view_context)
  end

  def show
    auction_to_show = Auction.find(params[:id])
    @auction = AuctionPresenter.new(auction_to_show, current_user, view_context)
  end

  def new
  end

  def create
    result = CreateAuction[auction_params.merge(:seller => current_user)]
    result.errors.blank? ? auction_created_response!(result) : no_auction_created_response!(result.errors)
  end


  private

  def auction_params
    @auction_params ||= AuctionParams.new(params[:auction_params]).attributes
  end

  def auction_created_response!(auction)
    flash[:notice] = "Auction was successfully created."
    render json: {auction_path: auction_path(auction.id)}
  end

  def no_auction_created_response!(errors)
    render json: {:errors => errors}, status: :unprocessable_entity
  end
end
