require 'httparty'
require 'nokogiri'

module Scraper
  class Client
    class << self
      PATH = "https://finance.yahoo.com/cryptocurrencies"

      def call(file)
        results = []

        number_of_results.each do |number|
          table_page  = HTTParty.get("#{PATH}?count=100&offset=#{number}")
          parsed_page = Nokogiri::HTML(table_page)
          parsed_page.xpath("//tr").each do |x|
            next if x.css("td").empty?
            symbol     = x.css("td")[0].text
            name       = x.css("td")[1].text
            price      = x.css("td")[2].text
            change     = x.css("td")[3].text
            market_cap = x.css("td")[5].text
            volume_24h = x.css("td")[7].text
            results << {
              symbol: symbol,
              name: name,
              price: price,
              change: change,
              market_cap: market_cap, 
              volume_24h: volume_24h,
              day_sparkline_data: chart_data(symbol)
            }
          end
        end

        json = results.to_json.gsub("{", "\n\t{")

        File.open(file, 'w') { |file| file.write(json) }
      end

      private

      def number_of_results
        (0..100*number_of_pages).step(100).to_a[0...-1]
      end

      def number_of_pages
        if total_results.remainder(100) > 0
          (total_results / 100) + 1
        else
          total_results / 100
        end
      end

      def total_results
        page = HTTParty.get(PATH)

        Nokogiri::HTML(page).xpath("//span[contains(text(),'results')]").text.split(' ')[2].to_i
      end

      def chart_data(symbol)
        chart_data = HTTParty.get("https://query1.finance.yahoo.com/v7/finance/spark?symbols=#{symbol}&range=1d&interval=1h&indicators=close&includeTimestamps=false&includePrePost=false&corsDomain=finance.yahoo.com&.tsrc=finance")
        sleep(rand(TMIN..TMAX).seconds)

        data = chart_data['spark']['result'].first['response'].first
        timestamps = data['timestamp']
        prices = data["indicators"]["quote"].first["close"]

        timestamps&.zip(prices)
      end
    end
  end
end