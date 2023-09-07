import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String> getIpAddress() async {
  final response =
      await http.get(Uri.parse('https://api.ipify.org?format=json'));

  if (response.statusCode == 200) {
    final ipAddress = json.decode(response.body)['ip'];
    return ipAddress;
  } else {
    throw Exception('Falha ao obter o endereço IP');
  }
}

class ClimateModel {
  final String name;
  final double temp;
  final String condition;
  final String imageTemp;

  ClimateModel({
    required this.name,
    required this.temp,
    required this.condition,
    required this.imageTemp,
  });

  factory ClimateModel.fromMap(Map<String, dynamic> map) {
    return ClimateModel(
      name: map['location']['name'],
      temp: (map['current']['temp_c'] as double),
      condition: map['current']['condition']['text'],
      imageTemp: map['current']['condition']['icon'],
    );
  }
}

abstract class IClimateRepository {
  Future<List<ClimateModel>> getClimate(String city);
}

class ClimateRepository implements IClimateRepository {
  final client = http.Client();
  final String API_KEY = '340a1713cb70427d88f181855233108';

  @override
  Future<List<ClimateModel>> getClimate(String city) async {
    final URL =
        'http://api.weatherapi.com/v1/forecast.json?key=$API_KEY&q=$city&days=1&aqi=no&alerts=no';
    print(URL);
    print(city);
    final response = await client.get(Uri.parse(URL));

    final body = jsonDecode(response.body);

    print(response.statusCode);

    if (response.statusCode == 200) {
      final List<ClimateModel> climates = [];

      final ClimateModel climate = ClimateModel.fromMap(body);

      climates.add(climate);

      return climates;
    } else if (response.statusCode == 400 || response.statusCode == 404) {
      print('erro elseif');
      throw Exception('Erro na requisição');
    } else {
      print('erro else');
      throw Exception('Não foi possível listar os dados');
    }
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final IClimateRepository repository = ClimateRepository();
  final TextEditingController cityController = TextEditingController();

  ClimateModel dataClimate = ClimateModel(
    name: '',
    temp: 0.0,
    condition: '',
    imageTemp: '',
  );

  bool isError = false;
  bool darkMode = false;

  final FocusNode _cityFocusNode = FocusNode();

  Future<void> _getClimateByIp(String ip) async {
    try {
      final climates = await repository.getClimate(ip);
      setState(() {
        dataClimate = climates[0];
        isError = false;
      });
    } catch (error) {
      setState(() {
        isError = true;
      });
      print('caiu aqui');
    }
  }

  Future<void> _getClimateByCity(String city) async {
    try {
      final climates = await repository.getClimate(city);
      setState(() {
        dataClimate = climates[0];
        isError = false;
      });
    } catch (error) {
      setState(() {
        isError = true;
      });
      print('caiu aqui');
    }
  }

  @override
  void initState() {
    super.initState();
    _getIpAddressAndFetchClimate();
  }

  Future<void> _getIpAddressAndFetchClimate() async {
    try {
      final ipAddress = await getIpAddress();

      await _getClimateByIp(ipAddress);
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClimaZord',
      theme: ThemeData(
        primaryColor: darkMode ? Colors.black : Colors.blue,
      ),
      home: Scaffold(
        backgroundColor: darkMode ? Colors.black : Colors.white,
        appBar: AppBar(
          title: Text('ClimaZord'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Switch(
                value: darkMode,
                onChanged: (value) {
                  setState(() {
                    darkMode = value;
                  });
                },
              ),
              Container(
                width: 200,
                height: 200,
                padding: EdgeInsets.all(0),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/climazord.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: TextField(
                  controller: cityController,
                  decoration: InputDecoration(labelText: 'Digite a cidade'),
                  focusNode: _cityFocusNode,
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _getClimateByCity(cityController.text);
                  _cityFocusNode.unfocus();
                },
                child: Text('Obter Clima'),
              ),
              isError == false
                  ? Container(child: ClimateCard(climate: dataClimate))
                  : Container(
                      child: Text(
                          'Campo ou vazio ou cidade inválida, tente novamente'))
            ],
          ),
        ),
      ),
    );
  }
}

class ClimateCard extends StatelessWidget {
  final ClimateModel climate;

  ClimateCard({required this.climate});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              climate.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '${climate.temp}°C',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10),
            Text(
              climate.condition,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            SizedBox(height: 10),
            Image.network('http:' + climate.imageTemp),
          ],
        ),
      ),
    );
  }
}
