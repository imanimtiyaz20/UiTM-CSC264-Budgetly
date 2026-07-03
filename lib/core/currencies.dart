class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;

  const CurrencyInfo(this.code, this.name, this.symbol);

  @override
  String toString() => '$symbol  $code';
}

const currencies = [
  CurrencyInfo('MYR', 'Malaysian Ringgit', 'RM'),
  CurrencyInfo('USD', 'US Dollar', '\$'),
  CurrencyInfo('EUR', 'Euro', '€'),
  CurrencyInfo('GBP', 'British Pound', '£'),
  CurrencyInfo('JPY', 'Japanese Yen', '¥'),
  CurrencyInfo('CNY', 'Chinese Yuan', '¥'),
  CurrencyInfo('KRW', 'South Korean Won', '₩'),
  CurrencyInfo('THB', 'Thai Baht', '฿'),
  CurrencyInfo('SGD', 'Singapore Dollar', 'S\$'),
  CurrencyInfo('IDR', 'Indonesian Rupiah', 'Rp'),
  CurrencyInfo('PHP', 'Philippine Peso', '₱'),
  CurrencyInfo('VND', 'Vietnamese Dong', '₫'),
  CurrencyInfo('INR', 'Indian Rupee', '₹'),
  CurrencyInfo('TRY', 'Turkish Lira', '₺'),
  CurrencyInfo('BRL', 'Brazilian Real', 'R\$'),
  CurrencyInfo('MXN', 'Mexican Peso', 'Mex\$'),
  CurrencyInfo('AUD', 'Australian Dollar', 'A\$'),
  CurrencyInfo('CAD', 'Canadian Dollar', 'C\$'),
  CurrencyInfo('CHF', 'Swiss Franc', 'Fr'),
  CurrencyInfo('NOK', 'Norwegian Krone', 'kr'),
  CurrencyInfo('SEK', 'Swedish Krona', 'kr'),
  CurrencyInfo('DKK', 'Danish Krone', 'kr'),
  CurrencyInfo('NZD', 'New Zealand Dollar', 'NZ\$'),
  CurrencyInfo('ZAR', 'South African Rand', 'R'),
  CurrencyInfo('AED', 'UAE Dirham', 'د.إ'),
  CurrencyInfo('SAR', 'Saudi Riyal', '﷼'),
];

String formatCurrency(double amount, String currencyCode) {
  final c = currencies.firstWhere(
    (c) => c.code == currencyCode,
    orElse: () => const CurrencyInfo('MYR', 'Malaysian Ringgit', 'RM'),
  );
  return '${c.symbol}${amount.toStringAsFixed(2)}';
}
