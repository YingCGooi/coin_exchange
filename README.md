# Coin Exchange Web Application
A mock digital currency exchange platform which allows users to buy and sell Bitcoin and Ethereum. This web application is built with Sinatra Ruby framework. Functionalities inspired by Coinbase exchange.

This app is also deployed in Heroku: https://coin-exchange-web-app-project.herokuapp.com/

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

Once Sinatra is running in the background, open up a web browser and enter `localhost:4567` in the URL address bar in order to begin.

### Sign-up Bonus
User will receive a sign-up bonus funding of virtual USD balance into their account, which can be used to purchase mock BTC or ETH.

#### Default User
If you do not wish to create a new account, the default user account is: 
- username: `admin`
- password: `secret`

### Automatic logging out
Signed-in user will be automatically logged out after a certain period of inactivity.

### Numbers
Prices are updated real-time - which means the web app's exchange rates follow the actual markets. A strict price validation is implemented (price swing within 0.5%) so that users may not be able to manipulate the inputs to buy/sell at a false exchange rate.

## Tests
To run tests:
```
bundle exec ruby test/cx_test.rb
```

Some tests on buying/selling (especially `test_buy_btc_or_eth_page`) will fail a number of times due to sudden changing in prices during the time of buy/sell. Many tests are asserted against real-time data, so you may expect some discrepancies to occur.

## Offline Mode
In the case where the application fails to fetch real-time data, the last retrieved price data will be used. This will apply to buy/sell prices as well as historical chart data.
It is possible to run the application entirely off-line. For the best user experience, it is recommended that you have an active Internet connection.

## API Utilization
Third-party APIs are used to include real-time BTC and ETH prices into the application and to display a 30-day BTC and ETH chart.
- API for real-time BTC and ETH prices: https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC,ETH&tsyms=USD
- API information for historical hourly price data: https://www.cryptocompare.com/api/#-api-data-histohour- 