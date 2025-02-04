require 'rails_helper'
require 'zdrofit_client'

RSpec.describe ZdrofitClient do
  let(:email) { "jan.kaczorowski@gmail.com" }
  let(:password) { "@MyBelovedCats1" }
  let(:client) { described_class.new(email, password) }

  describe '#login' do
    it 'authenticates successfully' do
      VCR.use_cassette('zdrofit_client/login_success') do
        expect { client.login }.not_to raise_error
        expect(client.instance_variable_get(:@auth_token)).not_to be_nil
      end
    end
  end

  describe '#list_available_clubs' do
    it 'returns list of clubs' do
      VCR.use_cassette('zdrofit_client/list_clubs') do
        clubs = client.list_available_clubs
        expect(clubs).to be_an(Array)
      end
    end
  end

  describe '#get_calendar_filters' do
    it 'returns calendar filters for a club' do
      VCR.use_cassette('zdrofit_client/calendar_filters') do
        filters = client.get_calendar_filters(club_id: 77)
        expect(filters).to be_a(Hash)
      end
    end
  end

  describe '#book_class' do
    it 'books a class successfully' do
      VCR.use_cassette('zdrofit_client/book_class') do
        result = client.book_class(class_id: 801539, club_id: 77)
        expect(result).to be_a(Hash)
      end
    end
  end

  # Add more tests for other methods...
end
