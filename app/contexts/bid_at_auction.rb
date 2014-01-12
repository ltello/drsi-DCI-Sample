# Auction Bidding Context:
#
#   The context for bidder to bids in an auction or to directly buy the item.
#
#   It includes two roleplayers:
#     - bidder:  the person creating the auction bid, to be played by an User instance.
#     - auction: the auction where to bid, played by an Auction instance.
#
#   An extra setting stating the amount to bid is needed:
#     - amount: the amount of money offered by the bidder to get the item.
#
class BidAtAuction < DCI::Context

  # A specific Exception class to throw errors when validation the bid conditions.
  # Respond to #errors with a list of error messages after validations run.
  class ValidationException < Exception
    def errors; [message] end
  end

  # Role definitions

    # The user trying to adquire the item of the auction.
    # An object playing to be the 'bidder' role should be a User instance.
    role :bidder do
      def is_last_bidder?
        auction.last_bidder == self
      end

      def bid
        auction.make_bid(self, settings(:amount))
      end
    end


    # The auction where to bid for the selling item.
    # This role must be played by an Auction instance.
    role :auction do

      # Creates a new Bid instance.
      # If the bid is for the buy_it_now_price of the auction, closes the auction with the bidder as winner.
      # Otherwise, tries to extend the auction end date if the bid is very near the end of the auction.
      # Returns the bid created or raises an InvalidRecordException in case of errors.
      def make_bid(bidder, amount)
        begin
          bids.create!(user: bidder, amount: amount).tap do |bid|
            bid.purchasing? ? CloseAuction[auction: self] : ExtendAuction[auction: self]
          end
        rescue ActiveRecord::RecordInvalid => e
          raise InvalidRecordException.new(e.record.errors.full_messages)
        end
      end
    end


  # Interactions

  # Creates and return a new bid in the auction.
  # If the bid does not validate properly, a ValidationException instance containing the error messages is returned.
  # The same occur with InvalidRecordException for errors in persisting record changes.
  # The auction gets closed with winner the bidder if the bid was actually a purchase for the buy_it_now_price of the item.
  def run
    begin
      validate!
      bidder.bid
    rescue ValidationException, InvalidRecordException => e
      e
    end
  end


  private

    def validate!
      validate_bidding_against_yourself
      validate_status
      validate_amount
      validate_against_last_bid
      validate_against_buy_it_now
    end

    def validate_bidding_against_yourself
      raise ValidationException, "Bidding against yourself is not allowed." if bidder.is_last_bidder?
    end

    def validate_status
      raise ValidationException, "Bidding on closed auction is not allowed." unless auction.started?
    end

    def validate_amount
      raise ValidationException, "Amount is not valid." unless settings(:amount).is_a?(Fixnum)
    end

    def validate_against_last_bid
      raise ValidationException, "The amount must be greater than the last bid." if auction.last_price.to_i >= settings(:amount)
    end

    def validate_against_buy_it_now
      raise ValidationException, "Bid cannot exceed the buy it now price." if settings(:amount) > auction.buy_it_now_price
    end

end
