class AuctionsExpirationCheckWorker
  include Sidekiq::Worker

  def perform
    Auction.find_in_batches do |auctions|
      auctions.each {|auction| CloseAuction[auction: auction] if auction.expired?}
    end
  end
end
