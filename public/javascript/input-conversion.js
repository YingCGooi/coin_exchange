  $(document).ready(function(){

    function alertFunds(value, balance) {
      $('div#primary-input').toggleClass('red-border', value > balance);
      $('p.alert-limit').toggle(value > balance);  
    };

    alertFunds(0, balance); // toggle alert message off when page loads
    
    $('#coin-input').on('keyup', function() {
      var input = $(this).val();
      var correspUsdValue = (input * currentCoinPrice);

      $('#usd-input').val(correspUsdValue.toFixed(2));
      if(!$(this).val()) { $('#usd-input').val('') };

      alertFunds($('input.primary').val(), balance);
    });

    $('#usd-input').on('keyup', function() {
      var input = $(this).val();
      var correspCoinValue = (input / currentCoinPrice);

      $('#coin-input').val(correspCoinValue.toFixed(6));
      if(!$(this).val()) { $('#coin-input').val('') };

      alertFunds($('input.primary').val(), balance);
    });
  });