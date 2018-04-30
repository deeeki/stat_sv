namespace :jcg do
  task result: :environment do
    TOUR     = 'https://sv.j-cg.com/compe/view/tour/'
    GAMELIST = 'https://sv.j-cg.com/compe/view/gamelist/'
    MATCH    = 'https://sv.j-cg.com/compe/view/match/'
    RESULT   = 'https://sv.j-cg.com/compe/view/result/'

    AGENT = Mechanize.new

    player_ranks = {}
    tour_id = ENV['TOUR'].scan(/\d+/).first

    result_page = AGENT.get(RESULT + tour_id)
    result_page.search('div#jcgcore_entry_list').each do |group_section|
      group_section.search('a.hover-blue').each_with_index do |player, i|
        user_id = player['href'].scan(/\d+/).first.to_i
        player_ranks[user_id] = { rank: i < 3 ? i + 1 : 3 }
      end
    end
    round = result_page.search('#jcgcore_head_menu h1.jcgcore-h1 span.nobr').last.text.strip
    name = result_page.at('.twitter-share-button')['data-text'].gsub(round, '').strip
    date = result_page.at('p.datetime').text.scan(%r[\d+/\d+/\d+]).first
    format = result_page.at('#jcgcore_category_menu h1.jcgcore-h1 a')['href'].split('/').last
    tournament = Tournament.find_or_create_by(id: tour_id, name: name, format: format, held_on: Date.parse(date), round: round)

    group_matches = {}
    gamelist_page = AGENT.get(GAMELIST + tour_id)
    gamelist_page.search('div#jcgcore_content_wrap > div.jcgcore_content').each do |group_section|
      group = group_section.at('h2.jcgcore-h2').text.scan(/\d+/).first
      group_matches[group] = group_section.search('a.hover-blue').map{|a| a['href'] }.select{|u| u.start_with?(MATCH) }.sort
    end

    group_matches.each do |group, matches|
      matches.each do |match_url|
        page = AGENT.get(match_url)

        players = []
        page.search('div.team_wrap').each do |team|
          player = team.at('a.hover-blue')
          user_id = player['href'].scan(/\d+/).first.to_i

          if stored_player = Player.find_by(tournament: tournament, user_id: user_id)
            players << stored_player
            next
          end

          player_name = player.text
          deck_url1, deck_url2 = team.search('a[target="_svp"]').map{|e| e['href'] }.map{|url|
            url.sub(%r[deckbuilder/create/\d\?hash=], 'deck/')
          }.sort

          user = User.find_or_create_by(id: user_id)
          user.update(name: player_name)

          players << user.players.create({
            tournament: tournament,
            group: group,
            name: player_name,
            deck_url1: deck_url1,
            deck_url2: deck_url2,
          }.merge(player_ranks[user_id] || {}))
        end

        match = Match.find_or_initialize_by(id: match_url.split('/').last, tournament: tournament)
        if match.new_record?
          left, right = page.search('p.score > span').map{|s| s.text.strip.to_i }
          if left > right
            won_player, lost_player = players.first, players.last
          else
            won_player, lost_player = players.last, players.first
          end
          round = page.at('div.breadcrumbs > ul > li.current').text.strip

          match.update(
            won_player: won_player,
            lost_player: lost_player,
            group: group,
            round: round,
            scores: [left, right]
          )
        end

        games = page.search('ul.game_list > li')
        if games.count == 3
          won_player_clans = {}
          games.each_with_index do |game, i|
            won_player_name = game.search('span')[2]&.text&.strip
            won_clan_name = game.search('span')[3]&.text&.strip
            if !won_player_name || !won_clan_name
              puts match_url
              next
            end

            won_player_clans = { won_player_name => won_clan_name }

            if i.zero?
              next # Can't detect 1st battle's lost clan/archetype
            else
              won_player = players.find{|p| p.name == won_player_name }
              lost_player = players.find{|p| p.name != won_player_name }
              won_clan = won_player.clans.find{|c| c.name == won_clan_name }
              lost_clan = lost_player.clans.find{|c| c.name != won_player_clans[lost_player.name] }

              next if !won_clan || !lost_clan

              Battle.find_or_create_by(
                tournament: tournament,
                format: format,
                match: match,
                battled_on: tournament.held_on,
                number: i + 1,
                won_player: won_player,
                lost_player: lost_player,
                won_clan: won_clan,
                lost_clan: lost_clan
              )
            end
          end
        end
      end
    end
    p tournament
    puts "Battle count: #{Battle.where(tournament: tournament).count}"
  end

  task update_archetypes: :environment do
    format = ENV['FORMAT'] ? ENV['FORMAT'] : :rotation
    tournament_ids = ENV['TOUR'] ? [ENV['TOUR'].scan(/\d+/).first] : Tournament.with_format(format).gte(held_on: Period.current.started_on).pluck(:id)
    players = Player.in(tournament_id: tournament_ids)
    players.each(&:update_archetypes)
  end

  task battle_stats: :environment do
    format = ENV['FORMAT'] ? ENV['FORMAT'] : :rotation
    period = Period.current
    require 'csv'
    wins = {}
    totals = {}
    archetypes = period.archetypes.with_format(format)
    archetypes.each do |a1|
      wins[a1.name] = {}
      totals[a1.name] = {}
      archetypes.each do |a2|
        wins[a1.name][a2.name] = 0
        totals[a1.name][a2.name] = 0
      end
    end

    Battle.with_format(format).gte(battled_on: period.started_on).each do |b|
      wins[b.won_archetype.name][b.lost_archetype.name] += 1
      totals[b.won_archetype.name][b.lost_archetype.name] += 1
      totals[b.lost_archetype.name][b.won_archetype.name] += 1
    end
    sorted_archetypes = totals.sort{|(k1, v1), (k2, v2)| v2.values.sum <=> v1.values.sum }.map{|k, v| k }

    csv_str = CSV.generate do |csv|
      csv << [nil, '試合数', '勝利数', '勝率'] + sorted_archetypes
      sorted_archetypes.each do |a1|
        cols = []
        sorted_archetypes.each do |a2|
          win = wins[a1][a2]
          total = totals[a1][a2]
          rate = total.zero? ? 'N/A' : (win.to_f / total).round(2) * 100
          cols << rate
        end
        total_count = totals[a1].values.sum
        win_count = wins[a1].values.sum
        rate = total_count.zero? ? 'N/A' : (win_count.to_f / total_count).round(2) * 100
        csv << [a1, total_count, win_count, rate] + cols
      end
    end
    File.write("battle_stats.csv", csv_str)
  end

  task qualifier_stats: :environment do
    require 'csv'
    DEFAULTS = { used: 0, qualified: 0, sample_url: nil }.freeze
    stats = {}

    format = ENV['FORMAT'] ? ENV['FORMAT'] : :rotation
    tournament_ids = ENV['TOUR'] ? [ENV['TOUR'].scan(/\d+/).first] : Tournament.with_format(format).where(round: /予選/).gte(held_on: Period.current.started_on).pluck(:id)
    players = Player.in(tournament_id: tournament_ids)
    players.each do |player|
      stats[player.archetype1] ||= DEFAULTS.dup
      stats[player.archetype2] ||= DEFAULTS.dup
      stats[player.archetype1][:used] += 1
      stats[player.archetype2][:used] += 1
      if player.rank == 1
        stats[player.archetype1][:qualified] += 1
        stats[player.archetype2][:qualified] += 1
      end
      stats[player.archetype1][:sample_url] ||= player.deck_url1
      stats[player.archetype2][:sample_url] ||= player.deck_url2
    end
    players_count = players.count
    qualified_count = players.where(rank: 1).count
    stats = Hash[stats.sort_by{|_, v| - v[:used] }]

    csv_str = CSV.generate do |csv|
      csv << %w[デッキタイプ 使用者 予選突破者 使用率 予選突破率 予選突破使用率 デッキ例]
      stats.each do |archetype, s|
        use_rate = (s[:used].to_f / players_count * 100).round(2)
        qualified_rate = (s[:qualified].to_f / s[:used] * 100).round(2)
        occupancy = (s[:qualified].to_f / qualified_count * 100).round(2)
        csv << [archetype.name, s[:used], s[:qualified], use_rate, qualified_rate, occupancy, s[:sample_url]]
      end
    end
    suffix = ENV['TOUR'] ? ENV['TOUR'] : Date.today.strftime('%Y%m')
    File.write("qualifier_stats_#{suffix}.csv", csv_str)
  end

  task usage_changes: :environment do
    require 'csv'
    changes = {}
    totals = {}

    format = ENV['FORMAT'] ? ENV['FORMAT'] : :rotation
    period = Period.current
    DEFAULTS = Hash[period.archetypes.with_format(format).map{|a| [a, 0] }].freeze
    Tournament.with_format(format).where(round: /予選/).gte(held_on: period.started_on).each do |tournament|
      stats = DEFAULTS.dup
      tournament.players.each do |player|
        stats[player.archetype1] += 1
        stats[player.archetype2] += 1
      end
      stats = Hash[stats.sort_by{|_, v| - v }]
      changes[tournament] = stats
      totals[tournament] = tournament.players.count
    end

    tournaments = changes.keys
    csv_str = CSV.generate do |csv|
      csv << ['デッキタイプ'] + tournaments.map(&:held_on)
      changes.values.last.each do |archetype, count|
        csv << [archetype.name] + tournaments.map{|t| ((changes[t][archetype] || 0).to_f / totals[t] * 100).round(2) }
      end
    end
    File.write("usage_changes.csv", csv_str)
  end

  task dump: :environment do
    require 'csv'
    tour_id = ENV['TOUR'].scan(/\d+/).first
    tournament = Tournament.find(tour_id)
    csv_str = CSV.generate do |csv|
      csv << %w[大会ID 日付 ユーザーID 名前 順位 デッキタイプ1 デッキタイプ2 デッキURL1 デッキURL2]
      tournament.players.sort_by{|p| p.rank || 5 }.each do |p|
        csv << [tour_id, tournament.held_on, p.user_id, p.name, p.rank, p.archetype1&.name, p.archetype2&.name, p.deck_url1, p.deck_url2]
      end
    end
    File.write("#{tour_id}.csv", csv_str)
  end
end
