import 'package:sweph/sweph.dart';
import 'lib/core/astro/astro_calculator.dart';
import 'dart:developer' as developer;

void main() async {
  await Sweph.init();
  final calculator = AstroCalculator();

  // Test getMoonPhaseTimes
  final testDate = DateTime.now();
  final phaseTimes = calculator.getMoonPhaseTimes(testDate);
  final phaseInfo = calculator.getMoonPhaseInfo(testDate);
  
  developer.log('Test Date: $testDate', name: 'repro_issue');
  developer.log('Current Moon Phase: ${phaseInfo['phaseName']}', name: 'repro_issue');
  developer.log('Phase Start: ${phaseTimes['start']}', name: 'repro_issue');
  developer.log('Phase End: ${phaseTimes['end']}', name: 'repro_issue');
  developer.log('Next Phase: ${calculator.findNextPhase(testDate)}', name: 'repro_issue');
}
