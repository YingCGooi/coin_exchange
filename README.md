# Coin Exchange Web Application

![coin exchange dashboard](https://i.imgur.com/I4kQ9q6.png)

A mock digital currency exchange platform which allows users to buy and sell Bitcoin and Ethereum based on actual real-time market price. This web application is built with Sinatra Ruby framework. Features inspired by Coinbase exchange.

This app is deployed in Heroku: https://coin-exchange-sinatra.herokuapp.com/

The goal of creating this application to practice translating high-level requirements into working code, integrating third-party web APIs and translating them into user-friendly interfaces and charts. Dynamic input forms were rendered through the use of jQuery.
Performance bottlenecks such as slow loading speed were addressed.

## Installation
Clone or download this git repository. Within the terminal opening the root of this project, execute the following line to install dependencies:

```
bundle install
```

## Usage
To run the server locally, execute:

```
bundle exec ruby cx.rb
```

Once Sinatra is running in the background, open up a web browser and enter `localhost:4567` in the URL address bar to begin.

## API Utilization
Third-party APIs are used to integrate real-time BTC and ETH prices into the application and to display a 30-day BTC and ETH chart.
- API for real-time BTC and ETH prices: https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC,ETH&tsyms=USD
- API information for historical hourly price data: https://www.cryptocompare.com/api/#-api-data-histohour

## Offline Mode
In the case where the application fails to fetch real-time data, the last retrieved price data will be used. This will apply to buy/sell prices as well as historical chart data.
It is possible to run the application entirely off-line. For the best user experience, it is recommended that you have an active Internet connection.

### Sign-up Bonus
User will receive a sign-up bonus funding of virtual USD balance into their account, which can be used to purchase mock BTC or ETH.

#### Default User
If you do not wish to create a new account, you can use the default credentials:
- username: `admin`
- password: `secret`

### Automatic logging out
Signed-in user will be automatically logged out after a certain period of inactivity. On every account action (buy/sell/page navigation), the idle time will be reset.

### Numbers
Prices are updated real-time - which means the web app's exchange rates follow the actual markets. A strict price validation is implemented (price swing within 0.5%) so that users may not be able to manipulate the inputs to buy/sell at a false exchange rate.

## Tests
To run tests:
```
bundle exec ruby test/cx_test.rb
```

Tests will now retrieve current price data from `cache_prices.yml`. This will prevent significant price fluctuations due to API response lagging time.

## Credits
Icon made by [Those Icons](https://www.flaticon.com/authors/those-icons) from www.flaticon.com

[Chartkick](https://www.chartkick.com/), together with Google Charts are used for drawing beautiful charts.

[Crytocompare API](https://www.cryptocompare.com/api/) is used as an API source for all of the real-time pricing and historical price data.

[LaunchSchool](https://launchschool.com) for providing me the education necessary to build a functioning web application.
