import 'forecast_params_data.dart';

/// Number of hour of week slots (Monday 00:00 is slot 0, Sunday 23:00 is slot 167).
const int forecastSlots = 168;

/// Parameters of the Home Forecast, fitted offline by AI/src/home_forecast.py.
class ForecastParams {
  const ForecastParams({
    required this.b0,
    required this.b1,
    required this.b2,
    required this.tauHours,
    required this.halfLifeDays,
    required this.priorStrength,
    required this.prior,
    this.eps = 1e-6,
  });

  factory ForecastParams.fromJson(Map<String, dynamic> json) {
    final prior = [
      for (final v in json['prior'] as List) (v as num).toDouble(),
    ];
    if (prior.length != forecastSlots) {
      throw FormatException('prior must have $forecastSlots values, got ${prior.length}');
    }
    return ForecastParams(
      b0: (json['b0'] as num).toDouble(),
      b1: (json['b1'] as num).toDouble(),
      b2: (json['b2'] as num).toDouble(),
      tauHours: (json['tau_hours'] as num).toDouble(),
      halfLifeDays: (json['half_life_days'] as num).toDouble(),
      priorStrength: (json['prior_strength'] as num).toDouble(),
      prior: prior,
      eps: ((json['eps'] ?? 1e-6) as num).toDouble(),
    );
  }

  final double b0;
  final double b1;
  final double b2;
  final double tauHours;
  final double halfLifeDays;
  final double priorStrength;
  final List<double> prior;
  final double eps;
}

/// The parameters shipped with the app (generated from AI/output/home_forecast.json).
final ForecastParams bundledForecastParams = ForecastParams.fromJson(forecastParamsJson);
