namespace :maintenance do
  task clear: :environment do
    format = ENV['FORMAT'] ? ENV['FORMAT'] : :rotation
    date = ENV['DATE'] ? Date.parse(ENV['DATE']) : Date.today.beginning_of_month
    Tournament.with_format(format).gte(held_on: date).each do |t|
      t.players.delete_all
      t.matches.delete_all
      t.battles.delete_all
      t.delete
    end
  end
end
