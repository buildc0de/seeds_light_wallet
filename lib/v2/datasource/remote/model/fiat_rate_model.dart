class FiatRateModel {
  Map<String?, num> rates;
  String? base;

  FiatRateModel(this.rates, {this.base = "USD"});

  factory FiatRateModel.fromJson(Map<String, dynamic> json) {
    if (json.isNotEmpty) {
      var model = FiatRateModel(Map<String, num>.from(json["rates"]), base: json["base"]);
      model.rebase("USD");
      return model;
    } else {
      return FiatRateModel({});
    }
  }

  double? usdTo(double usdValue, String currency) {
    num? rate = rates[currency];
    if(rate != null) {
      return usdValue * rate;
    } else {
      return null;
    }
  }

  double? toUSD(double currencyValue, String currency) {
    num? rate = rates[currency];
    if(rate != null) {
      // ignore: unnecessary_statements
      rate > 0 ? currencyValue / rate : 0;
    } else {
      return null;
    }
  }

  void rebase(String symbol) {
    var rate = rates[symbol];
    if (rate != null) {
      rates[base] = 1.0;
      base = symbol;
      rates = rates.map((key, value) => MapEntry(key, value / rate));
      rates[base] = 1.0;
    } else {
      print("error - can't rebase to " + symbol);
    }
  }
}
