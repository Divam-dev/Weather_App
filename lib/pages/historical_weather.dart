import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/apis/historical_weather_api.dart';
import 'package:weather_app/components/graph_card.dart';
import 'package:weather_app/components/searchbar.dart';
import 'package:weather_app/forecast/historical/graph_list_component.dart';
import 'package:weather_app/forecast/historical/historical_precipitation.dart';
import 'package:weather_app/forecast/historical/historical_sun.dart';
import 'package:weather_app/forecast/historical/historical_tempetature.dart';
import 'package:weather_app/forecast/historical/historical_wind.dart';

import '../apis/geo.dart';
import '../preferences_storage.dart';

class HistoricalWeather extends StatefulWidget {
  const HistoricalWeather({super.key});

  @override
  State<StatefulWidget> createState() => _HistoricalWeather();
}

class _HistoricalWeather extends State<HistoricalWeather> {
  @override
  void initState() {
    super.initState();
    updateText();
    // loadFromStorage();
  }

  //region attributes
  final TextEditingController searchTextController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final SearchController searchController = SearchController();

  List<Widget> suggestions = [];
  BuildContext? sheetContext;
  DateTime lastWeatherUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  DateTime _start = DateTime.now().subtract(const Duration(days: 5));
  DateTime _end = DateTime.now().subtract(const Duration(days: 2));

  Geo? selectedGeo;

  DateFormat formatter = DateFormat.yMd();

  bool isWeatherReady = false;

  HistoricalPrecipitation? precipitation;
  HistoricalSun? sun;
  HistoricalTemperature? temperature;
  HistoricalWind? wind;

  List<Object?> ApiResults = [null, null, null, null];

  bool _apiError = false;
  String _apiMessage = "";

  final List<String> CardTitles = [
    "Температура",
    "Опади",
    "Сонячне сяйво",
    "Вітер"
  ];
  //endregion

  Future loadFromStorage() async {
    return;
  }

  Future geocodeCurrentLocation() async {
    setState(() {
      isWeatherReady = false;
    });
    try {
      Geo current = await Geo.getLocation();
      current = await Geo.geocodeCurrentLocation(current);

      setState(() {
        if (current.city != null) searchTextController.text = current.city!;
        selectedGeo = current;
      });
    } catch (exception) {
      print("AAAA");
    }

    getWeatherForSelectedGeo();
  }

  Future getWeatherForSelectedGeo() async {
    if (selectedGeo == null) return;

    setState(() {
      _apiError = false;
    });

    HistoricalWeatherApi weather = HistoricalWeatherApi(
        geo: selectedGeo, startDate: _start, endDate: _end);

    try {
      ApiResults[0] = await weather.call_api_temperature();
      ApiResults[1] = await weather.call_api_precipitation();
      ApiResults[2] = await weather.call_api_sun();
      ApiResults[3] = await weather.call_api_wind();
    } catch (ex) {
      print("Las exceptiones: ${ex.toString()}");

      setState(() {
        _apiError = true;
        _apiMessage = (ex as Error).stackTrace.toString();
      });
    }

    lastWeatherUpdate = DateTime.now();

    // storeGeo();

    setState(() {
      isWeatherReady = true;
    });
  }

  void updateText() {
    _startDateController.text = formatter.format(_start);
    _endDateController.text = formatter.format(_end);
  }

  Future showDateDialog(DateTime date, BuildContext context,
      {bool isStart = false}) async {
    DateTime? newDate = await showDatePicker(
        context: context,
        firstDate: (isStart) ? DateTime(1940) : _start,
        lastDate: (!isStart)
            ? DateTime.now().subtract(const Duration(days: 2))
            : _end,
        initialDate: date,
        initialEntryMode: DatePickerEntryMode.calendarOnly);

    if (newDate != null) {
      if (isStart) {
        _start = newDate;
      } else {
        _end = newDate;
      }

      updateText();
      setState(() {});
    }
  }

  List<GraphListComponent> convertApiToComponents(int index) {
    List<GraphListComponent> components = [];

    if (index == 0) {
      HistoricalTemperature temp = (ApiResults[index] as HistoricalTemperature);
      components.add(GraphListComponent(
          list: temp.temperatureMax,
          title: "Максимальна температура",
          color: GraphListComponent.colors[3]));
      components.add(GraphListComponent(
          list: temp.temperatureMean,
          title: "Середня температура",
          color: GraphListComponent.colors[4]));
      components.add(GraphListComponent(
          list: temp.temperatureMin,
          title: "Мінімальна температура",
          color: GraphListComponent.colors[5]));
    } else if (index == 1) {
      HistoricalPrecipitation precipitation =
          (ApiResults[index] as HistoricalPrecipitation);
      components.add(GraphListComponent(
          list: precipitation.rainSums,
          title: "Загальна кількість дощу",
          color: GraphListComponent.colors[0]));
      components.add(GraphListComponent(
          list: precipitation.snowfallSums,
          title: "Загальна кількість снігу",
          color: GraphListComponent.colors[1]));
      components.add(GraphListComponent(
          list: precipitation.precipitationSums,
          title: "Загальна кількість опадів",
          color: GraphListComponent.colors[3]));
    } else if (index == 2) {
      HistoricalSun sun = (ApiResults[index] as HistoricalSun);
      components.add(GraphListComponent(
          list: sun.daylightDurations,
          title: "Тривалість світлового дня",
          color: GraphListComponent.colors[0]));
    } else {
      HistoricalWind wind = (ApiResults[index] as HistoricalWind);
      components.add(GraphListComponent(
          list: wind.windSpeeds,
          title: "Швидкість вітру",
          color: GraphListComponent.colors[0]));
      components.add(GraphListComponent(
          list: wind.windGusts,
          title: "Пориви вітру",
          color: GraphListComponent.colors[1]));
      components.add(GraphListComponent(
          list: wind.windDirections,
          title: "Напрямок вітру",
          color: GraphListComponent.colors[2]));
    }

    return components;
  }

  TextStyle headerStyle = const TextStyle(fontSize: 14);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: () async {
          if (selectedGeo != null && isWeatherReady == true) {
            setState(() {
              isWeatherReady = false;
            });
            getWeatherForSelectedGeo();
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).viewPadding.top),
            SizedBox(
                height: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).viewPadding.top -
                    80,
                child: CustomScrollView(
                  slivers: <Widget>[
                    SliverAppBar(
                      pinned: true,
                      leadingWidth: 0,
                      expandedHeight: 160,
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.all(12),
                        collapseMode: CollapseMode.none,
                        expandedTitleScale: 1,
                        title: Container(
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                SuggestingSearchBar(
                                    searchController: searchController,
                                    textController: searchTextController,
                                    geocodeLocation: geocodeCurrentLocation,
                                    weatherApiCall: getWeatherForSelectedGeo,
                                    setGeo: (Geo geo) {
                                      selectedGeo = geo;
                                      setState(() {});
                                    },
                                    setError: (String? error) {},
                                    updateWeatherReadiness: (bool state) {
                                      isWeatherReady = state;
                                      setState(() {});
                                    }),
                                Expanded(
                                    child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                        height: 70,
                                        width: MediaQuery.sizeOf(context).width,
                                        child: GridView.count(
                                          crossAxisCount: 2,
                                          primary: false,
                                          crossAxisSpacing: 12,
                                          clipBehavior: Clip.none,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          children: [
                                            TextField(
                                              controller: _startDateController,
                                              decoration: InputDecoration(
                                                border:
                                                    const OutlineInputBorder(),
                                                label:
                                                    const Text("Дата початку"),
                                                suffixIcon: IconButton(
                                                  icon: const Icon(Icons.start),
                                                  onPressed: () {
                                                    showDateDialog(
                                                        _start, context,
                                                        isStart: true);
                                                  },
                                                ),
                                              ),
                                            ),
                                            TextField(
                                              controller: _endDateController,
                                              decoration: InputDecoration(
                                                border:
                                                    const OutlineInputBorder(),
                                                label: const Text("Дата кінця"),
                                                suffixIcon: IconButton(
                                                  icon: const Icon(
                                                      Icons.last_page_rounded),
                                                  onPressed: () {
                                                    showDateDialog(
                                                        _end, context);
                                                  },
                                                ),
                                              ),
                                            )
                                          ],
                                        ))
                                  ],
                                ))
                              ],
                            )),
                      ),
                    ),
                    if (selectedGeo != null)
                      if (isWeatherReady)
                        SliverList(
                            delegate: SliverChildBuilderDelegate(
                                (BuildContext context, int index) {
                          if (ApiResults[index] != null) {
                            return Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                child: GraphCard(
                                  graphStart: _start,
                                  graphEnd: _end,
                                  graphLines: convertApiToComponents(index),
                                  title: CardTitles[index],
                                ));
                          }
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Text("Error getting ${CardTitles[index]}"),
                                    const Text("API error message"),
                                    Expanded(
                                      child: Text(_apiMessage),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        }, childCount: CardTitles.length))
                      else if (!_apiError)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                              (context, index) => const Center(
                                  child: Padding(
                                      padding: EdgeInsets.all(48),
                                      child: SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: CircularProgressIndicator(),
                                      ))),
                              childCount: 1),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                              (context, index) => Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: [
                                        const Text("API Error!"),
                                        Expanded(child: Text(_apiMessage))
                                      ],
                                    ),
                                  ),
                              childCount: 1),
                        )
                  ],
                ))
          ],
        ));
  }
}
