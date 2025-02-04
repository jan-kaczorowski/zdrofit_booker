module ZdrofitClient
  class Client
    include HTTParty
    base_uri "https://zdrofit.perfectgym.pl/ClientPortal2"

    attr_reader :auth_token
    attr_reader :authenticated_headers

    API_CALLS = {
      list_weekly_classes: ZdrofitClient::ApiCalls::ListWeeklyClasses,
      book_class: ZdrofitClient::ApiCalls::BookClass,
      list_available_clubs: ZdrofitClient::ApiCalls::ListAvailableClubs,
      get_calendar_filters: ZdrofitClient::ApiCalls::GetCalendarFilters,
      get_identity: ZdrofitClient::ApiCalls::GetIdentity,
      get_class_tickets: ZdrofitClient::ApiCalls::GetClassTickets,
      summarize_booking_cancellation: ZdrofitClient::ApiCalls::SummarizeBookingCancellation,
      cancel_booking: ZdrofitClient::ApiCalls::CancelBooking,
      get_my_calendar: ZdrofitClient::ApiCalls::GetMyCalendar,
      get_personal_id_info: ZdrofitClient::ApiCalls::GetPersonalIdInfo,
      get_phone_info: ZdrofitClient::ApiCalls::GetPhoneInfo,
      get_profile_for_edit: ZdrofitClient::ApiCalls::GetProfileForEdit
    }.freeze

    def initialize(login, password)
      @login = login
      @password = password
      @auth_token = nil
      @default_headers = {
        "Accept" => "application/json, text/plain, */*",
        "Accept-Language" => "pl",
        "CP-LANG" => "pl",
        "CP-MODE" => "desktop",
        "Content-Type" => "application/json",
        "Origin" => "https://zdrofit.perfectgym.pl",
        "Referer" => "https://zdrofit.perfectgym.pl/ClientPortal2/",
        "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36"
      }
      @authenticated_headers = @default_headers
    end

    def login
      response = self.class.post(
        "/Auth/Login",
        headers: @default_headers,
        body: {
          RememberMe: false,
          Login: @login,
          Password: @password
        }.to_json
      )

      raise "Login failed: #{response.body}" unless response.success?

      @auth_token = response.headers["jwt-token"]
      @authenticated_headers = @default_headers.merge({
        "Authorization" => "Bearer #{@auth_token}"
      })

      self
    end

    def method_missing(method_name, *args, **kwargs)
      if API_CALLS.key?(method_name)
        ensure_authenticated
        API_CALLS[method_name].new(self).call(**kwargs)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      API_CALLS.key?(method_name) || super
    end

    private

    def ensure_authenticated
      login if @auth_token.nil?
    end
  end
end
