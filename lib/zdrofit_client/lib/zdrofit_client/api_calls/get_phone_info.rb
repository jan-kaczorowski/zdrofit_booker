module ZdrofitClient
  module ApiCalls
    class GetPhoneInfo < ApiCall
      def call(phone_number:, country_symbol: "PL")
        post(
          "/PersonalData/GetPhoneInfo",
          body: {
            phoneNumber: phone_number,
            phoneNumberCountrySymbol: country_symbol
          }
        )
      end
    end
  end
end 