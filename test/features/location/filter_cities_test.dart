import 'package:activehood/features/location/domain/user_location.dart';
import 'package:flutter_test/flutter_test.dart';

CityOption _c(String n) => CityOption(name: n, lat: 0, lng: 0, placesCount: 1);

void main() {
  final cities = [_c('Bytom'), _c('Łódź'), _c('Tarnowskie Góry'), _c('Kraków')];

  test('ignoruje polskie znaki i wielkość liter', () {
    expect(filterCities(cities, 'lodz').map((c) => c.name), ['Łódź']);
    expect(filterCities(cities, 'KRAKOW').map((c) => c.name), ['Kraków']);
  });

  test('najpierw dopasowania od początku, potem w środku', () {
    final r = filterCities([
      _c('Ruda Śląska'),
      _c('Gory'),
      _c('Tarnowskie Góry'),
    ], 'gor');
    expect(r.map((c) => c.name), ['Gory', 'Tarnowskie Góry']);
  });

  test('pusta fraza zwraca wszystkie', () {
    expect(filterCities(cities, '  '), hasLength(4));
  });
}
