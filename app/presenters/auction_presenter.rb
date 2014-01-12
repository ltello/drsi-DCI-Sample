class AuctionPresenter

  delegate :name, :description,                 :to => :item,   :prefix => true
  delegate :name,                               :to => :seller, :prefix => true
  delegate :name,                               :to => :winner, :prefix => true, :allow_nil => true
  delegate :buy_it_now_price, :id, :created_at, :to => :auction
  delegate :extendable, :status, :last_price,   :to => :auction


  def initialize(auction, current_user, view_context)
    @auction      = auction
    @item         = auction.item
    @seller       = auction.seller
    @winner       = auction.winner
    @view_context = view_context
    @current_user = current_user
  end

  def render_end_date
    return "" unless auction.end_date
    h.content_tag :dl, class: "dl-horizontal" do
      h.content_tag(:dt, "End Date") +
      h.content_tag(:dd, auction.end_date, id: "end-date")
    end
  end

  def render_winner
    return "" unless winner
    h.content_tag :dl, class: "dl-horizontal" do
      h.content_tag(:dt, "Winner") +
      h.content_tag(:dd, winner_name, id: "winner")
    end
  end

  def render_last_bid
    return "" unless auction.last_bid
    h.content_tag :dl, class: "dl-horizontal" do
      h.content_tag(:dt, "Last Bid") +
        h.content_tag(:dd, auction.last_bid.amount.to_s, id: "last-bid")
    end
  end

  def render_all_bids
    return "" unless seller?
    h.content_tag :ul, id: "bids" do
      h.content_tag(:h3, "All Bids") + all_bids
    end
  end

  def render_actions
    "".tap do |res|
      res << render_bid_button if can_bid?
      res << render_buy_it_now_button if can_bid?
    end.html_safe
  end

  def number_of_bids
    auction.bids.count
  end


  private

  attr_reader :auction, :item, :seller, :winner, :view_context, :current_user

  def all_bids
    auction.bids.map do |bid|
      h.content_tag :li do
        "#{bid.user.name} bids $#{bid.amount}"
      end.html_safe
    end.join("").html_safe
  end

  def seller?
    auction.seller == current_user
  end

  def can_bid?
    auction.started? && auction.seller != current_user
  end

  def render_buy_it_now_button
    h.link_to "Buy It Now!", h.buy_auction_bids_path(id), class: "btn", method: "POST", id: "buy_it_now"
  end

  def render_bid_button
    h.render partial: "bid", locals: {auction_id: id}
  end

  def h
    view_context
  end
end
