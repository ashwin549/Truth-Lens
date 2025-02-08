import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DailyTab extends StatefulWidget {
  @override
  _DailyTabState createState() => _DailyTabState();
}

class _DailyTabState extends State<DailyTab> {
  Map<String, dynamic> _weatherData = {};
  Map<String, dynamic> _currencyData = {};
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Weather API call using Weatherstack
      final weatherResponse = await http.get(
        Uri.parse('http://api.weatherstack.com/current?access_key=c24c27b33945087055831f1df60d7903&query=Udupi'),
      );

      // Currency API call (using ExchangeRate-API - you'll need an API key)
      final currencyResponse = await http.get(
        Uri.parse('https://v6.exchangerate-api.com/v6/dc7c5b4937fd2c1b43fd15b2/latest/INR'),
      );

      if (weatherResponse.statusCode == 200 && currencyResponse.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(weatherResponse.body);
          _currencyData = json.decode(currencyResponse.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text(_error))
          : RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWeatherCard(),
              SizedBox(height: 16),
              _buildCurrencyCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (_weatherData.isEmpty || _weatherData['current'] == null) return SizedBox.shrink();

    final current = _weatherData['current'];
    final location = _weatherData['location'];

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weather in ${location['name']}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Image.network(
                  current['weather_icons'][0],
                  width: 50,
                  height: 50,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.error_outline),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text('Temperature: ${current['temperature']}°C'),
            Text('Weather: ${current['weather_descriptions'][0]}'),
            Text('Humidity: ${current['humidity']}%'),
            Text('Wind: ${current['wind_speed']} km/h ${current['wind_dir']}'),
            Text('Feels like: ${current['feelslike']}°C'),
            Text('Pressure: ${current['pressure']} mb'),
            Text('UV Index: ${current['uv_index']}'),
            Text('Visibility: ${current['visibility']} km'),
            Text('Last Updated: ${current['observation_time']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyCard() {
    if (_currencyData.isEmpty) return SizedBox.shrink();

    final rates = _currencyData['conversion_rates'] ?? {};
    final currencies = ['EUR', 'USD', 'JPY', 'AUD'];

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Currency Exchange Rates (INR)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            ...currencies.map((currency) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '1 INR = ${rates[currency]?.toStringAsFixed(2) ?? 'N/A'} $currency',
              ),
            )),
          ],
        ),
      ),
    );
  }
}