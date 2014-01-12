# Auction Extension Context:
#
#   The context to extend the end date of an auction.
#
#   It includes one roleplayer:
#     - auction: the auction to be extended.
#
class ExtendAuction < DCI::Context
  EXTENDING_INTERVAL = 30.minutes

  # Role definitions

    # The auction to be extended.
    # This role must be played by an Auction instance.
    role :auction do

      # Tries to extend the auction end date for the given interval if it is started, extendable and
      # the current end date is within that interval.
      # Returns true if ex´tended or false otherwise.
      def maybe_extend_end_date(interval = EXTENDING_INTERVAL)
        return false unless can_be_extended?
        begin
          self.end_date = interval.since end_date
          save!
        rescue ActiveRecord::RecordInvalid => e
          InvalidRecordException.new(e.record.errors.full_messages)
        end
      end


      private

        # EXTENDING_INTERVAL = 30.minutes

        def almost_closed?
          (end_date - Time.now) < EXTENDING_INTERVAL
        end

        def can_be_extended?
          extendable and started? and almost_closed?
        end
    end


  # Interactions

  # Tries to extend the auction if it is extendable is started and right now the end of the auction is very near.
  def run
    auction.maybe_extend_end_date
  end

end
