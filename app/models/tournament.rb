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

  def period
    @period ||= Period.lte(started_on: held_on).order(started_on: :desc).first
  end

  def dump
    players.sort_by{|p| p.rank || 5 }.map do |p|
      [id, held_on, p.user_id, p.name, p.rank, p.archetype1&.name, p.archetype2&.name, p.deck_url1, p.deck_url2]
    end
  end

  def usage
    counts = Hash[period.archetypes.with_format(format).map{|a| [a.name, 0] }]
    players.each do |player|
      counts[player.archetype1.name] += 1 if player.archetype1
      counts[player.archetype2.name] += 1 if player.archetype2
    end
    total = players.count
    Hash[counts.sort_by{|_, v| -v }.map{|name, count| [name, (count.to_f / total * 100).round(2)] }]
  end
end
