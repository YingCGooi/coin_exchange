## Coin Exchange Web Application
A mock digital currency exchange platform which allows users to buy and sell Bitcoin and Ethereum.

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

Once Sinatra is running in the background, open up a web browser and request `localhost:4567` in the URL address bar to begin.

### API Utilization
Third-party APIs are used to include real-time BTC and ETH prices into the application and to display a 30-day BTC chart.
- API for 30-day chart: https://api.coindesk.com/v1/bpi/historical/close.json
- API for real-time BTC and ETH prices: https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC,ETH&tsyms=USD

### Sign-up Bonus
User will receive a sign-up bonus funding of virtual USD balance into their account, which can be used to purchase mock BTC or ETH.

### Automatic logging out
Signed-in user will be automatically logged out after a certain period of inactivity.

### Numbers
Prices are updated real-time - which means the web app's exchange rates follow the actual markets. A price validation is implemented so that users may not be able to manipulate the inputs to buy/sell at a false exchange rate.

### Tests
To run tests:
```
bundle exec ruby test/cx_test.rb
```

Some tests will fail the first or second try due the timing where the real time prices are updated. Many tests are asserted against real-time data, so discrepancies may occur.


