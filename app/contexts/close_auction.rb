# Auction Closing Context:
#
#   The context to finish an auction.
#
#   It includes only one roleplayer:
#     - auction: the auction to be finish, played by an Auction instance.
#
class CloseAuction < DCI::Context

  # Role definitions

    # The auction to be finished.
    # This role must be played by an Auction instance.
    role :auction do

      # Closes the auction player, assigning the last bidder as winner or nil if no bidders.
      # If for some reason, errors occur during the process, the auction is restored to its previous status
      #   and the winner is not set.
      def close_with_or_without_winner
        preserving_fields(:winner, :status) do
          self.winner = last_bidder
          close
        end
      end


      private

        # Executes the given block preserving the values of the given fields in case of error:
        #   If an error occurs inside the block, the fields values prior to the block execution and
        #   restored before re raising the Exception.
        def preserving_fields(*fields, &block)
          previous_field_values = fields.inject({}) {|h, field| h.merge!(field => send(field))}
          begin
            block.call
          rescue ActiveRecord::RecordInvalid => e
            previous_field_values.each {|field, value| send("#{field}=", value)}
            raise InvalidRecordException.new(e.record.errors.full_messages)
          end
        end
    end


  # Interactions

  # Closes an auction assigning the last bidder as winner if any.
  # If something goes wrong, an InvalidRecordException containing the error messages is returned.
  def run
    begin
      auction.close_with_or_without_winner
    rescue InvalidRecordException => e
      e
    end
  end
end
