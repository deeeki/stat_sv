AGENT = Mechanize.new

COMPE_LIST = 'https://sv.j-cg.com/past-schedule/'
RESULTS    = 'https://sv.j-cg.com/competition/%s/results'
BRACKET    = 'https://sv.j-cg.com/competition/%s/bracket#/1'
API        = 'https://sv.j-cg.com/api/'

namespace :jcg do
  task fetch: :environment do
    format = ENV['FORMAT'] ? ENV['FORMAT'] : :rotation

    compe_list_page = AGENT.get(COMPE_LIST + format.to_s)
    tours = compe_list_page.search('div.schedule-list-item').map do |item|
      OpenStruct.new({
        url: item.at('a.schedule-link')['href'],
        id: item.at('a.schedule-link')['href'].split('/').last,
        status: item.at('div.schedule-status').text.strip,
      })
    end.reverse

    tours.each do |tour|
      next unless tour.status == '終了'
      next if Tournament.find_by(id: tour.id)
      ENV['TOUR'] = tour.id
      Rake::Task['jcg:result'].execute
    end
  end

  task result: :environment do
    tour_id = ENV['TOUR']

    player_ranks = {}
    results_page = AGENT.get(RESULTS % tour_id)
    results_page.search('div.competition-result-item > div.result').each do |result|
      rank = result['class'][-1]
      user_nicename = result.at('div.result-name > a')['href'].split('/').last
      player_ranks[user_nicename] = { rank: rank.to_i }
    end
    round = results_page.at('div.competition-title').text.split(' ').last
    name = results_page.at('div.competition-title').text.gsub(round, '').strip
    month_day = results_page.at('div.competition-date').text.split(' ').first
    year = Date.today.month == 1 && month_day.start_with?('12') ? Date.today.year - 1 : Date.today.year
    format = name.include?('ローテーション') ? 'rotation' : 'unlimited'
    tournament = Tournament.find_or_create_by(id: tour_id, name: name, format: format, held_on: Date.parse("#{year}.#{month_day}"), round: round)

    group_matches = {}
    bracket_page = AGENT.get(BRACKET % tour_id)
    bracket = JSON.parse(bracket_page.at('div.content-inner > script').text.gsub('_INLINE_BRACKET_DATA = ', ''))
    bracket['groups'].each do |bracket_group|
      url = %[#{API}competition/group/#{bracket_group['id']}]
      json_group = JSON.parse(URI.open(url).read)
      group_matches[bracket_group['code']] = json_group['rounds'].map{|r| r['matches'].map{|m|
        { id: m['id'], group: bracket_group['code'], round: r['name'], scores: m['teams'].map{|t| t['wins'] } }
      }}.flatten
    end

    group_matches.each do |group_code, matches|
      matches.each do |match_attrs|
        url = %[#{API}competition/match/#{match_attrs[:id]}]
        json_match = JSON.parse(URI.open(url).read)

        players = []
        json_match['teams'].each do |team|
          json_user = team['users'].first
          if stored_player = Player.find_by(tournament: tournament, user_id: json_user['user'])
            players << stored_player
            next
          end

          deck_url1, deck_url2 = Nokogiri::HTML(json_user['customText']).search('a').map{|a| a['href'] }.map{|url|
            url.sub(%r[deckbuilder/create/\d\?hash=], 'deck/')
          }.sort

          user = User.find_or_create_by(id: json_user['user'])
          user.update(name: json_user['name'], nicename: json_user['nicename'])

          players << user.players.create({
            tournament: tournament,
            group: group_code,
            name: user.name,
            deck_url1: deck_url1,
            deck_url2: deck_url2,
          }.merge(player_ranks[team['nicename']] || {}))
        end

        match = tournament.matches.find_or_initialize_by(id: match_attrs[:id])
        if match.new_record?
          if match_attrs['scores'].first > match_attrs['scores'].last
            match_attrs.merge(won_player: players.first, lost_player: players.last)
          else
            match_attrs.merge(won_player: players.last, lost_player: players.first)
          end

          match.update(match_attrs)
        end
      end
    end
    p tournament
  end

  task update_archetypes: :environment do
    format = ENV['FORMAT'] ? ENV['FORMAT'] : :rotation
    tournament_ids = ENV['TOUR'] ? [ENV['TOUR'].scan(/\d+/).first] : Tournament.with_format(format).gte(held_on: Period.current.started_on).pluck(:id)
    players = Player.in(tournament_id: tournament_ids)
    players = players.where(archetype1: nil, archetype2: nil) unless ENV['FORCE']
    players.each(&:update_archetypes)
  end

  task export: [:usage, :usage_combi, :battle, :winrate, :final, :qualifier, :stats]

  task usage: :environment do
    changes = {}
    totals = {}

    format = ENV['FORMAT'] ? ENV['FORMAT'] : :rotation
    period = Period.current
    defaults = Hash[period.archetypes.with_format(format).map{|a| [a, 0] }].freeze
    Tournament.with_format(format).where(round: /予選/).gte(held_on: period.started_on).order(held_on: :asc).each do |tournament|
      stats = defaults.dup
      tournament.players.each do |player|
        stats[player.archetype1] += 1 if player.archetype1
        stats[player.archetype2] += 1 if player.archetype2
      end
      stats = Hash[stats.sort_by{|_, v| - v }]
      changes[tournament] = stats
      totals[tournament] = tournament.players.count
    end

    tournaments = changes.keys
    rows = [['デッキタイプ'] + tournaments.map(&:held_on)]
    changes.values.last.each do |archetype, count|
      rows << [archetype.name] + tournaments.map{|t| ((changes[t][archetype] || 0).to_f / totals[t] * 100).round(2) }
    end

    Writer.google_drive("#{format.to_s.first}Usage", rows)
  end

  task usage_combi: :environment do
    changes = {}
    totals = {}

    format = ENV['FORMAT'] ? ENV['FORMAT'] : :rotation
    period = Period.current
    Tournament.with_format(format).where(round: /予選/).gte(held_on: period.started_on).order(held_on: :asc).each do |tournament|
      stats = {}
      skipped_count = 0
      tournament.players.each do |player|
        if !player.archetype1 || !player.archetype2
          skipped_count += 1
          next
        end
        combi = [player.archetype1.name, player.archetype2.name].join(' | ')
        stats[combi] ||= 0
        stats[combi] += 1
      end
      stats = Hash[stats.sort_by{|_, v| - v }]
      changes[tournament] = stats
      totals[tournament] = tournament.players.count - skipped_count
    end

    tournaments = changes.keys
    rows = [[''] + tournaments.map(&:held_on)]
    changes.values.last.keys.each do |combi|
      rows << [combi] + tournaments.map{|t| ((changes[t][combi] || 0).to_f / totals[t] * 100).round(2) }
    end

    Writer.google_drive("#{format.to_s.first}Combi", rows)
  end

  task stats: :environment do
    defaults = { used: 0, qualified: 0, sample_url: nil }.freeze
    stats = {}

    format = ENV['FORMAT'] ? ENV['FORMAT'] : :rotation
    tournament_ids = ENV['TOUR'] ? [ENV['TOUR']] : Tournament.with_format(format).where(round: /予選/).gte(held_on: Period.current.started_on).pluck(:id)
    players = Player.in(tournament_id: tournament_ids)
    players.each do |player|
      stats[player.archetype1] ||= defaults.dup
      stats[player.archetype2] ||= defaults.dup
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

    rows = [%w[デッキタイプ 使用者 予選突破者 使用率 予選突破率 予選突破使用率 デッキ例]]
    stats.each do |archetype, s|
      use_rate = (s[:used].to_f / players_count * 100).round(2)
      qualified_rate = (s[:qualified].to_f / s[:used] * 100).round(2)
      occupancy = (s[:qualified].to_f / qualified_count * 100).round(2)
      rows << [archetype&.name, s[:used], s[:qualified], use_rate, qualified_rate, occupancy, s[:sample_url]]
    end

    ws_name = ENV['TOUR'] ? Tournament.find_by(id: ENV['TOUR']).held_on.strftime('%y%m%d') : Date.today.strftime('%Y%m')
    Writer.google_drive(ws_name, rows)
  end

  task qualifier: :environment do
    format = ENV['FORMAT'] ? ENV['FORMAT'] : :rotation
    period = Period.current
    rows = [%w[大会ID 日付 ユーザーID ユーザー名 グループ デッキタイプ1 デッキタイプ2 デッキURL1 デッキURL2]]
    Tournament.with_format(format).where(round: /予選/).gte(held_on: period.started_on).order(held_on: :desc).each do |tournament|
      rows += tournament.players.where(rank: 1).map do |p|
        [tournament.id, tournament.held_on, p.user_id, p.name, p.group, p.archetype1&.name, p.archetype2&.name, p.deck_url1, p.deck_url2]
      end
    end

    Writer.google_drive("#{format.to_s.first}Qualifier", rows)
  end

  task final: :environment do
    format = ENV['FORMAT'] ? ENV['FORMAT'] : :rotation
    period = Period.current
    rows = [%w[大会ID 日付 ユーザーID ユーザー名 順位 デッキタイプ1 デッキタイプ2 デッキURL1 デッキURL2]]
    Tournament.with_format(format).where(round: /決勝/).gte(held_on: period.started_on).order(held_on: :desc).each do |tournament|
      rows += tournament.dump
    end

    Writer.google_drive("#{format.to_s.first}Final", rows)
  end

  task battle: :environment do
    format = ENV['FORMAT'] ? ENV['FORMAT'] : :rotation

    stats = Battle.stats(format: format)
    sorted_archetypes = stats.battles.sort{|(k1, v1), (k2, v2)| v2.values.sum <=> v1.values.sum }.map{|k, v| k }

    header = ['', '試合数', '勝利数', '勝率'] + sorted_archetypes
    rows = [header.map{|c| c.split('').join("\n") }]
    sorted_archetypes.each do |a1|
      archetype_cols = sorted_archetypes.map{|a2| stats.formula_rates[a1][a2] }
      battles_count = stats.battles[a1].values.sum
      wins_count = stats.wins[a1].values.sum
      total_rate = battles_count.zero? ? 'N/A' : (wins_count.to_f / battles_count * 100).round(2)
      rows << [a1, battles_count, wins_count, total_rate] + archetype_cols
    end

    Writer.google_drive("#{format.to_s.first}Battle", rows)
  end

  task winrate: :environment do
    format = ENV['FORMAT'] ? ENV['FORMAT'] : :rotation
    date_from = ENV['DATE_FROM'] ? ENV['DATE_FROM'] : nil

    tournament = Tournament.with_format(format).where(round: /予選/).order(held_on: :desc).first
    top_usage = tournament.usage.take(10).to_h
    archetype_names = top_usage.keys
    stats = Battle.stats(format: format, date_from: date_from)

    header = ['', '使用率込勝率'] + top_usage.keys
    rows = [header.map{|c| c.split('').join("\n") }]
    rows << ['(使用率)', '=SUM(C2:L2)'] + top_usage.values
    archetype_names.each.with_index(3) do |archetype_name, i|
      part = ('C'..'L').map{|col| "#{col}#{i}*#{col}$2" }.join('+')
      formula = "=ROUND((#{part})/B$2,1)"
      rows << [archetype_name, formula] + archetype_names.map{|n| stats.formula_rates[archetype_name][n] }
    end

    Writer.google_drive("#{format.to_s.first}Winrate#{date_from}", rows)
  end
end
