# Auction Creation Context:
#
#   The context to create and start new auctions.
#
#   It includes only one roleplayer:
#     - seller: the person creating the auction played by an user instance.
#
#   Some extra settings describing the auction to be created are needed:
#     - item_name:        the name of the item to be sold in the auction.
#     - buy_it_now_price: the price a bidder must offer to automatically buy the item and close the auction.
#     - end_date:         the time the auction finishes.
#
#   Two more extra optional settings:
#     - item_description: the description of the item to sell in the auction.
#     - extendable:       wether the auction can be extended for a few more minutes or not after bidding near the end_date.
#
class CreateAuction < DCI::Context

  # Role definitions

    # The user owner of the item to be sold in the auction.
    # An object playing to be the 'seller' role must be a User instance.
    role :seller do

      # Creates a new item, an auction to sell it and starts that auction.
      # Returns the new auction or an InvalidRecordException instance with error messages in #errors if something goes wrong.
      def start_auction
        begin
          auction if auction.start
        rescue ActiveRecord::RecordInvalid => e
          item.destroy if @item.try(:persisted?)
          InvalidRecordException.new(e.record.errors.full_messages)
        end
      end


      private

        # The item to be sold in the new auction. Creates it if it wasn't created yet.
        def item
          attrs = {name: settings(:item_name), description: settings(:item_description)}
          @item ||= Item.create!(attrs)
        end

        # The new auction. Creates it if it wasn't created yet'.
        def auction
          attrs = {seller: self}.merge!(settings.slice(:buy_it_now_price, :end_date, :extendable)).merge!(item: item)
          @auction ||= Auction.create!(attrs)
        end

    end


  # Interactions

  # Creates a new item, and an started auction to sell it.
  # If something goes wrong, an InvalidRecordException containing the error messages is returned.
  def run
    seller.start_auction
  end

end
