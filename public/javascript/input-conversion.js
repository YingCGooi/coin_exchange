  $(document).ready(function(){

    function alertFunds(value, balance) {
      $('#usd-input-box').toggleClass('red-border', value > balance);
      $('p.alert-limit').toggle(value > balance);  
    };

    alertFunds(0, balance); // toggle alert message off when page loads
    $('#coin-input').on('keyup', function() {
      var input = $(this).val();
      var correspUsdValue = (input * currentCoinPrice);

      alertFunds(correspUsdValue, balance);

      $('#usd-input').val(correspUsdValue.toFixed(2));
      if(!$(this).val()) { $('#usd-input').val('') };
    });

    $('#usd-input').on('keyup', function() {
      var input = $(this).val();
      var correspCoinValue = (input / currentCoinPrice);

      alertFunds(input, balance);

      $('#coin-input').val(correspCoinValue.toFixed(6));
      if(!$(this).val()) { $('#coin-input').val('') };
    });
  });