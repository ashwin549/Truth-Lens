import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

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
    String apiKey_1 = dotenv.env['API_KEY_1'] ?? 'Default value';
    String city = 'Udupi';
    String apiKey_2 = dotenv.env['API_KEY_2'] ?? 'Default value';
    try {
      // Weather API call using Weatherstack
      final weatherResponse = await http.get(
        Uri.parse('http://api.weatherstack.com/current?access_key=$apiKey_1&query=$city'),
      );

      // Currency API call (using ExchangeRate-API - you'll need an API key)
      final currencyResponse = await http.get(
        Uri.parse('https://v6.exchangerate-api.com/v6/$apiKey_2/latest/INR'),
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
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlue.shade200, Colors.lightBlue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row with title and weather icon inside a decorated circle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Weather in ${location['name']}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade900,
                    ),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.network(
                      current['weather_icons'][0],
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.error_outline),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(color: Colors.blueGrey.shade300),
            SizedBox(height: 16),
            // Weather details rows
            _buildInfoRow(Icons.thermostat_outlined, 'Temperature', '${current['temperature']}°C'),
            _buildInfoRow(Icons.wb_sunny_outlined, 'Condition', current['weather_descriptions'][0]),
            _buildInfoRow(Icons.water_damage_outlined, 'Humidity', '${current['humidity']}%'),
            _buildInfoRow(
                Icons.air_outlined, 'Wind', '${current['wind_speed']} km/h ${current['wind_dir']}'),
            _buildInfoRow(Icons.thermostat_rounded, 'Feels like', '${current['feelslike']}°C'),
            _buildInfoRow(Icons.speed_outlined, 'Pressure', '${current['pressure']} mb'),
            _buildInfoRow(Icons.brightness_high_outlined, 'UV Index', '${current['uv_index']}'),
            _buildInfoRow(Icons.visibility, 'Visibility', '${current['visibility']} km'),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Last Updated: ${current['observation_time']}',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build individual rows for weather info
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey.shade600),
          SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey.shade800),
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.blueGrey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyCard() {
    if (_currencyData.isEmpty) return SizedBox.shrink();

    final rates = _currencyData['conversion_rates'] ?? {};
    final currencies = ['EUR', 'USD', 'JPY', 'AUD'];

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade200, Colors.green.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Currency Exchange Rates (INR)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
            SizedBox(height: 16),
            Divider(color: Colors.green.shade300),
            ...currencies.map(
                  (currency) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currency,
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '1 INR = ${rates[currency]?.toStringAsFixed(2) ?? 'N/A'} $currency',
                      style: TextStyle(fontSize: 16, color: Colors.green.shade800),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
