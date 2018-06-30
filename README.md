# README

## When a new card set released

* Refresh all card data

```sh
rake portal:cards:setup
```

* Add card set code

Add a new card set code to `app/models/period.rb`


## When card-balance changed

* Add a new period

```sh
# Modify db/seeds.rb beforehand
rake db:seed
```

* Define archetype conditions for current period

Save to `config/archetypes/{CARD_SET_CODE}_{FORMAT}_{PERIOD_START_DATE}.yml`

* Create archetypes

```sh
rake maintenance:archetype
```
