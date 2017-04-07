# Boost Production Script (Regression)
Production scipt to test customer workflow

## Install
```
bundle install

```

## Run rspec

`bundle exec rspec spec/desktop/table_wp_integration.rb`

`for i in {1..5}; do bundle exec rspec spec/desktop/table_wp_integration.rb >> output.txt; done`
