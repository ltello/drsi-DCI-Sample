class Bid < ActiveRecord::Base
  attr_accessible :amount, :user, :auction

  belongs_to :user
  belongs_to :auction

  validates :user_id,    presence:     true
  validates :auction_id, presence:     true
  validates :amount,     numericality: true

  # This bid is a purchase!
  def purchasing?
    auction.buy_it_now_price == amount
  end
end
