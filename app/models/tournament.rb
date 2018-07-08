class Tournament
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Enumerize
  field :name, type: String
  field :format, type: String
  field :held_on, type: Date
  field :round, type: String
  enumerize :format, in: [:rotation, :unlimited], default: :rotation, scope: true
  has_many :players, dependent: :delete_all
  has_many :matches, dependent: :delete_all
  has_many :battles, dependent: :delete_all

  def dump
    players.sort_by{|p| p.rank || 5 }.map do |p|
      [id, held_on, p.user_id, p.name, p.rank, p.archetype1&.name, p.archetype2&.name, p.deck_url1, p.deck_url2]
    end
  end
end
