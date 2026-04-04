# Zdrofit Booker Development Guide

## Commands
- Server: `bin/rails server` or `bin/dev` (with JS/CSS hot reloading)
- Tests: `bin/rails test` or `bundle exec rspec spec/path/to/file_spec.rb`
- Single test: `bin/rails test test/models/zdrofit_user_test.rb:LINE_NUMBER`
- RSpec single test: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
- Linting: `bin/rubocop` or `bin/rubocop -a` (auto-fix)
- Security check: `bin/brakeman`
- Run jobs: `bin/rails jobs:work`

## Code Style
- Classes use CamelCase: `ZdrofitClassBooking`, `ClassBookerJob`
- Methods/variables use snake_case: `booking_time`, `book_class`
- Service objects: Use class methods pattern (`ClassBooker.call(booking)`)
- Error handling: Rescue specific exceptions, update models to reflect failures
- Models: Follow ActiveRecord conventions with descriptive associations
- Callbacks: Used sparingly, prefer explicit service objects for complex logic
- Testing: Use RSpec, VCR for API mocks, FactoryBot for test data
- Method length: Keep methods focused and under 10 lines when possible
- Private methods: Extract helper methods to keep public interface clean