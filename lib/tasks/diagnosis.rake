namespace :diagnosis do
  task failed_decks: :environment do
    format = ENV['FORMAT'] ? ENV['FORMAT'] : :rotation
    tournament_ids = Tournament.with_format(format).gte(held_on: Period.current.started_on).pluck(:id)
    players = Player.in(tournament_id: tournament_ids)
    decks = []
    players.each do |player|
      clan_ids = player.archetypes.compact.map(&:clan_id)
      next if clan_ids.count == 2
      player.deck_urls.each do |deck_url|
        clan_id = deck_url.split('/').last[2].to_i
        next if clan_ids.include?(clan_id)
        decks << OpenStruct.new(url: deck_url, player: player)
      end
    end

    clan_index = Hash[Clan.pluck(:id, :name)]
    rows = [%w[クラス プレイヤー]]
    decks.each do |deck|
      hash_str = deck.url.split('/').last
      clan_id = hash_str[2].to_i
      d = Card.human_convert(hash_str)
      rows << [clan_index[clan_id], deck.player.name] + d.to_a.flatten
    end

    Writer.csv('tmp/failed_decks.csv', rows)
  end
end
