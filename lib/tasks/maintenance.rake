namespace :maintenance do
  task archetype: :environment do
    Dir.glob(Rails.root.join('config/archetypes/*.yml')).each do |yaml|
      card_set_code, format, date = File.basename(yaml, '.yml').split('_')
      period = Period.find_by(card_set_code: card_set_code, started_on: Date.parse(date))
      YAML.load_file(yaml).each do |archetype_attrs|
        period.archetypes.find_or_create_by(archetype_attrs.merge(format: format))
      end
    end
  end

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
