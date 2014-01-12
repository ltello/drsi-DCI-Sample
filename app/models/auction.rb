class Auction < ActiveRecord::Base
  attr_accessible :seller, :item, :buy_it_now_price, :status, :end_date, :extendable

  belongs_to :item
  belongs_to :winner, :class_name => 'User'
  belongs_to :seller, :class_name => 'User'
  has_many :bids

  PENDING  = 'pending'
  STARTED  = 'started'
  CLOSED   = 'closed'
  CANCELED = 'canceled'

  validates :status, inclusion: {in: [PENDING, STARTED, CLOSED, CANCELED], allow_blank: false}
  validates :item_id, presence: true
  validates :seller_id, presence: true
  validates :end_date, presence: true
  validates :buy_it_now_price, :numericality => true

  validate :buyer_and_seller_are_different
  validate :end_date_period

  before_validation :set_pending_status, on: :create

  def start
    self.status = STARTED
    save!
  end

  def close
    self.status = CLOSED
    save!
  end

  def started?;    status == STARTED              end
  def expired?;    started? and end_date_in_past? end
  def closed?;     status == CLOSED               end
  def last_bid;    bids.last                      end
  def last_bidder; last_bid.try(:user)            end
  def last_price;  last_bid.try(:amount)          end


  private

    def end_date_in_past?; end_date < DateTime.current end


  # Validators

    def end_date_period
      errors.add(:end_date, "must be in the future") if end_date && end_date_in_past?
    end

    def buyer_and_seller_are_different
      errors.add(:winner, "can't be equal to seller") if seller_id == winner_id
    end


  # Callbacks

    def set_pending_status
      self.status = PENDING
    end
end
