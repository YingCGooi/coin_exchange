## Coin Exchange Web Application
A mock digital currency exchange platform which allows users to buy and sell Bitcoin and Ethereum. This web application is built with Sinatra Ruby framework. Functionalities inspired by Coinbase exchange.

### Installation
Clone or download this git repository. Open the repository as the current working directory within the terminal. Then execute the following line to install dependencies:

```
bundle install
```

### Usage
To run the server locally, execute:

```
bundle exec ruby cx.rb
```

Once Sinatra is running in the background, open up a web browser and request `localhost:4567` in the URL address bar in order to begin.

### API Utilization
Third-party APIs are used to include real-time BTC and ETH prices into the application and to display a 30-day BTC chart.
- API for real-time BTC and ETH prices: https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC,ETH&tsyms=USD
- API information for historical hourly price data: https://www.cryptocompare.com/api/#-api-data-histohour- 

### Sign-up Bonus
User will receive a sign-up bonus funding of virtual USD balance into their account, which can be used to purchase mock BTC or ETH.

### Automatic logging out
Signed-in user will be automatically logged out after a certain period of inactivity.

### Numbers
Prices are updated real-time - which means the web app's exchange rates follow the actual markets. A strict price validation is implemented (price swing within 0.5%) so that users may not be able to manipulate the inputs to buy/sell at a false exchange rate.

### Tests
To run tests:
```
bundle exec ruby test/cx_test.rb
```

Some tests on buying/selling (especially `test_buy_btc_page`) will fail a number of times due the difference in prices where the API data is updated during the time of buy. Many tests are asserted against real-time data, so discrepancies may occur.

### Offline Mode
It is possible to run the server entirely off-line. In this case, prices will be randomized within a certain range. Charts will not be displayed. For the best user experience, it is recommended that you have an active Internet connection.
