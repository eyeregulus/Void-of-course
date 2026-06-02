// 이 파일은 별자리와 달의 움직임 같은 것을 계산하는 '점성술 계산기'예요.
// 달이 어떤 별자리에 있는지, 달의 모양(위상)은 어떤지 같은 것을 알려줘요.
// 'sweph'라는 아주 정확한 계산을 해주는 도구를 사용해요.
import 'package:sweph/sweph.dart'; // 천문학 계산을 위한 'sweph' 도구를 가져와요.

// 점성술에 필요한 것들을 계산하는 특별한 상자(클래스)예요.
class AstroCalculator {
  // 열두 별자리의 기호를 순서대로 적어놓은 목록이에요.
  static const List<String> zodiacSigns = [
    '♈︎',
    '♉︎',
    '♊︎',
    '♋︎',
    '♌︎',
    '♍︎',
    '♎︎',
    '♏︎',
    '♐︎',
    '♑︎',
    '♒︎',
    '♓︎',
  ];

  static const List<String> aspectSigns = ['☌', '✶', '□', '△', '☍'];

  static const List<String> planetSigns = [
    '☉',
    '☿',
    '♀',
    '♂',
    '♃',
    '♄',
    '♅',
    '♆',
    '⯓',
  ];

  // 열두 별자리의 영어 이름을 순서대로 적어놓은 목록이에요.
  static const List<String> zodiacNames = [
    'Aries',
    'Taurus',
    'Gemini',
    'Cancer',
    'Leo',
    'Virgo',
    'Libra',
    'Scorpio',
    'Sagittarius',
    'Capricorn',
    'Aquarius',
    'Pisces',
  ];

  // 달의 모양(위상)을 이름과 함께 적어놓은 목록이에요.
  static const List<String> moonPhaseNames = [
    '🌑 New Moon', //뉴문
    '🌒 Crescent Moon', // 초승달
    '🌓 First Quarter', // 상현달
    '🌔 Gibbous Moon', // 지보스문
    '🌕 Full Moon', // 보름달
    '🌖 Disseminating Moon', //디세미네이팅 문
    '🌗 Last Quarter', // 하현달
    '🌘 Balsamic Moon', // 그믐달
  ];

  // 해와 달을 제외한 주요 행성들을 목록으로 만들었어요.
  static const List<HeavenlyBody> majorPlanets = [
    HeavenlyBody.SE_SUN,
    HeavenlyBody.SE_MERCURY,
    HeavenlyBody.SE_VENUS,
    HeavenlyBody.SE_MARS,
    HeavenlyBody.SE_JUPITER,
    HeavenlyBody.SE_SATURN,
    HeavenlyBody.SE_URANUS,
    HeavenlyBody.SE_NEPTUNE,
    HeavenlyBody.SE_PLUTO,
  ];

  // 점성술에서 중요하다고 여기는 각도(어스펙트)들을 목록으로 만들었어요.
  static const List<double> majorAspects = [0, 60, 90, 120, 180];

  // 날짜와 시간을 '줄리안 데이'라는 특별한 숫자로 바꿔주는 함수예요.
  // 천문학자들은 이 숫자로 날짜를 더 쉽게 계산해요.
  double getJulianDay(DateTime date) {
    final utcDate = date.toUtc(); // 시간을 모든 나라에서 똑같은 'UTC' 시간으로 바꿔요.
    final jdList = Sweph.swe_utc_to_jd(
      // 'sweph' 도구를 써서 줄리안 데이를 계산해요.
      utcDate.year,
      utcDate.month,
      utcDate.day,
      utcDate.hour,
      utcDate.minute,
      utcDate.second.toDouble(),
      CalendarType.SE_GREG_CAL,
    );
    return jdList[0]; // 계산된 줄리안 데이 숫자만 가져와요.
  }

  // 어떤 별이나 행성의 위치(경도)를 찾아주는 함수예요.
  double getLongitude(HeavenlyBody body, DateTime date) {
    final jd = getJulianDay(date); // 먼저 날짜를 줄리안 데이로 바꿔요.
    final pos = Sweph.swe_calc_ut(
      jd,
      body,
      SwephFlag.SEFLG_SWIEPH,
    ); // 'sweph' 도구로 위치를 계산해요.
    return pos.longitude; // 계산된 경도(위치)를 알려줘요。
  }

  // 해와 달의 위치(경도)를 동시에 찾아주는 함수예요.
  Map<String, double> getSunMoonLongitude(DateTime date) {
    final jd = getJulianDay(date);
    final sun = Sweph.swe_calc_ut(
      jd,
      HeavenlyBody.SE_SUN,
      SwephFlag.SEFLG_SWIEPH,
    );
    final moon = Sweph.swe_calc_ut(
      jd,
      HeavenlyBody.SE_MOON,
      SwephFlag.SEFLG_SWIEPH,
    );
    return {'sun': sun.longitude, 'moon': moon.longitude};
  }

  // 달의 현재 모양(위상)이 무엇인지 찾아주는 함수예요.
  Map<String, dynamic> getMoonPhaseInfo(DateTime date) {
    final positions = getSunMoonLongitude(date); // 해와 달의 위치를 가져와요.
    final sunLon = positions['sun']!;
    final moonLon = positions['moon']!;
    final angle = Sweph.swe_degnorm(moonLon - sunLon); // 해와 달 사이의 각도를 계산해요.

    String phaseName; // 달의 모양 이름을 담을 상자예요.
    if (angle < 45) {
      phaseName = '🌑 New Moon'; // 각도가 45도보다 작으면 '초승달'
    } else if (angle < 90) {
      phaseName = '🌒 Crescent Moon'; // 각도가 90도보다 작으면 '상현달'
    } else if (angle < 135) {
      phaseName = '🌓 First Quarter';
    } else if (angle < 180) {
      phaseName = '🌔 Gibbous Moon';
    } else if (angle < 225) {
      phaseName = '🌕 Full Moon'; // 각도가 180도보다 작으면 '보름달'
    } else if (angle < 270) {
      phaseName = '🌖 Disseminating Moon';
    } else if (angle < 315) {
      phaseName = '🌗 Last Quarter';
    } else {
      phaseName = '🌘 Balsamic Moon';
    }

    return {'phaseName': phaseName}; // 달의 모양 이름을 알려줘요.
  }

  // 다음 주요 달의 모양(초승달, 상현달, 보름달, 하현달)이 언제인지 찾아주는 함수예요.
  Map<String, dynamic> findNextPrimaryPhase(DateTime date) {
    final now = date;

    // 주요 달 모양과 그 각도를 미리 정해놔요.
    final phases = {
      0.0: '🌑 New Moon',
      90.0: '🌓 First Quarter',
      180.0: '🌕 Full Moon',
      270.0: '🌗 Last Quarter',
    };

    DateTime? bestTime; // 가장 가까운 시간을 담을 상자예요.
    String? bestName; // 가장 가까운 달 모양 이름을 담을 상자예요.

    // 각 달 모양을 차례대로 확인해요.
    for (var entry in phases.entries) {
      final targetAngle = entry.key;
      final name = entry.value;

      final positions = getSunMoonLongitude(now);
      final currentAngle = Sweph.swe_degnorm(
        positions['moon']! - positions['sun']!,
      );

      // 목표 각도까지 얼마나 남았는지 계산해요.
      var degToGo = (targetAngle - currentAngle + 360) % 360;
      if (degToGo < 0.5) {
        degToGo += 360;
      }

      // 달은 하루에 약 12.19도씩 움직여요. 이걸로 대략적인 시간을 계산해요.
      var daysToGo = degToGo / 12.19;
      DateTime estimatedTime = now.add(
        Duration(microseconds: (daysToGo * 24 * 3600 * 1000000).round()),
      );

      // 정확한 시간을 다시 찾아봐요.
      var time = _findSpecificPhaseTime(
        estimatedTime,
        targetAngle,
        daysRange: 2,
      );

      // 만약 찾은 시간이 지금보다 전이라면, 다음 달 주기로 넘어가서 다시 찾아봐요.
      if (time != null && time.isBefore(now)) {
        time = _findSpecificPhaseTime(
          estimatedTime.add(const Duration(days: 28)),
          targetAngle,
          daysRange: 3,
        );
      }

      // 가장 가까운 시간을 찾아서 저장해요.
      if (time != null) {
        if (bestTime == null || time.isBefore(bestTime)) {
          bestTime = time;
          bestName = name;
        }
      }
    }

    return {'name': bestName, 'time': bestTime}; // 가장 가까운 달 모양과 시간을 알려줘요.
  }

  // 다음 달 모양이 언제인지 찾아주는 함수예요. (주요 모양이 아니라도)
  Map<String, dynamic> findNextPhase(DateTime date) {
    final now = date;

    // 1. 현재 해와 달의 각도를 계산해요.
    final positions = getSunMoonLongitude(now);
    final currentAngle = Sweph.swe_degnorm(
      positions['moon']! - positions['sun']!,
    );

    // 2. 현재 각도에 따라 다음 달 모양의 각도와 이름을 정해요.
    double nextAngle;
    String nextName;

    if (currentAngle < 45) {
      nextAngle = 45.0;
      nextName = '🌒 Crescent Moon';
    } else if (currentAngle < 90) {
      nextAngle = 90.0;
      nextName = '🌓 First Quarter';
    } else if (currentAngle < 135) {
      nextAngle = 135.0;
      nextName = '🌔 Gibbous Moon';
    } else if (currentAngle < 180) {
      nextAngle = 180.0;
      nextName = '🌕 Full Moon';
    } else if (currentAngle < 225) {
      nextAngle = 225.0;
      nextName = '🌖 Disseminating Moon';
    } else if (currentAngle < 270) {
      nextAngle = 270.0;
      nextName = '🌗 Last Quarter';
    } else if (currentAngle < 315) {
      nextAngle = 315.0;
      nextName = '🌘 Balsamic Moon';
    } else {
      // 현재 각도가 315도 이상이라면, 다음은 다시 초승달(New Moon)이에요.
      nextAngle = 0.0;
      nextName = '🌑 New Moon';
    }

    // 3. 다음 달 모양이 나타나는 정확한 시간을 찾아봐요.
    var degToGo = (nextAngle - currentAngle + 360) % 360;
    if (degToGo == 0) degToGo = 360; // 안전을 위한 코드예요.

    var daysToGo =
        degToGo / (360 / 29.530588861); // 달 주기를 이용해 대략적인 시간을 계산해요.
    DateTime estimatedTime = now.add(
      Duration(microseconds: (daysToGo * 24 * 3600 * 1000000).round()),
    );

    // 대략적인 시간을 기준으로 정확한 시간을 다시 찾아봐요.
    DateTime? finalTime = _findSpecificPhaseTime(
      estimatedTime,
      nextAngle,
      daysRange: 2,
    );

    return {'name': nextName, 'time': finalTime}; // 다음 달 모양과 시간을 알려줘요.
  }

  // 달이 현재 어떤 별자리에 있는지 기호로 알려주는 함수예요.
  String getMoonZodiacEmoji(DateTime date) {
    final moonLon = getLongitude(HeavenlyBody.SE_MOON, date); // 달의 위치를 가져와요.
    final signIndex = ((moonLon % 360) / 30).floor(); // 위치를 별자리 번호로 바꿔요.
    return zodiacSigns[signIndex]; // 별자리 기호를 알려줘요.
  }

  String getMoonSignName(DateTime date) {
    final moonLon = getLongitude(HeavenlyBody.SE_MOON, date);
    final signIndex = ((moonLon % 360) / 30).floor();
    // 인덱스가 범위를 벗어나지 않도록 안전장치 추가
    if (signIndex >= 0 && signIndex < zodiacNames.length) {
      return zodiacNames[signIndex];
    }
    return 'Aries'; // 기본값
  }

  // 달이 특정 별자리에 들어오고 나가는 시간을 찾아주는 함수예요.
  Map<String, DateTime?> getMoonSignTimes(DateTime date) {
    final moonLon = getLongitude(HeavenlyBody.SE_MOON, date); // 달의 위치를 가져와요.
    final currentSignLon = (moonLon / 30).floor() * 30.0; // 현재 별자리의 시작 위치를 찾아요.
    final nextSignLon = (currentSignLon + 30.0) % 360; // 다음 별자리의 시작 위치를 찾아요.

    DateTime? signStartTime; // 별자리에 들어오는 시간
    DateTime? signEndTime; // 별자리에서 나가는 시간

    // 달이 현재 별자리에 들어온 시간을 찾아봐요.
    final utcStartTime = _findTimeOfLongitude(
      date.subtract(const Duration(days: 4)), // 4일 전부터 오늘까지 찾아봐요.
      date,
      currentSignLon,
    );
    if (utcStartTime != null) {
      signStartTime = utcStartTime;
    }

    // 달이 다음 별자리로 나가는 시간을 찾아봐요.
    final utcEndTime = _findTimeOfLongitude(
      date,
      date.add(const Duration(days: 3)), // 오늘부터 3일 후까지 찾아봐요.
      nextSignLon,
    );
    if (utcEndTime != null) {
      signEndTime = utcEndTime;
    }

    return {'start': signStartTime, 'end': signEndTime}; // 들어오고 나가는 시간을 알려줘요.
  }

  Map<String, dynamic> getMoonPhaseTimes(DateTime date) {
    // Strategy: Reuse existing findNextPhase() for endTime (which does binary search)
    // For startTime: search backwards to find phase change, then get time when it started

    final currentPhaseInfo = getMoonPhaseInfo(date);
    final currentPhaseName = currentPhaseInfo['phaseName'];

    // End time + next phase name: findNextPhase() 한 번으로 둘 다 가져오기
    final nextPhaseInfo = findNextPhase(date);
    final endTime = nextPhaseInfo['time'] as DateTime?;
    final nextPhaseName = nextPhaseInfo['name'] as String?;

    // Start time: 1일 단위로 먼저 경계를 찾고, 6시간 단위로 좁히기
    DateTime? startTime;
    var backSearchDate = date.subtract(const Duration(days: 1));

    // 1일 단위로 phase 변경 지점을 빠르게 탐색 (달 위상은 최대 ~4.5일)
    DateTime? boundaryDate;
    for (int i = 0; i < 6; i++) {
      final phaseAtDate = getMoonPhaseInfo(backSearchDate)['phaseName'];
      if (phaseAtDate != currentPhaseName) {
        boundaryDate = backSearchDate;
        break;
      }
      backSearchDate = backSearchDate.subtract(const Duration(days: 1));
    }

    // 경계를 찾았으면 6시간 단위로 좁혀서 정확한 전환점 찾기
    if (boundaryDate != null) {
      var refinedDate = boundaryDate;
      var narrowDate = refinedDate.add(const Duration(days: 1));
      for (int i = 0; i < 4; i++) {
        narrowDate = narrowDate.subtract(const Duration(hours: 6));
        if (getMoonPhaseInfo(narrowDate)['phaseName'] != currentPhaseName) {
          refinedDate = narrowDate;
          break;
        }
      }
      final prevPhaseInfo = findNextPhase(refinedDate);
      startTime = prevPhaseInfo['time'] as DateTime?;
    }

    return {'start': startTime, 'end': endTime, 'nextPhaseName': nextPhaseName};
  }

  DateTime? _findSpecificPhaseTime(
    DateTime date,
    double targetAngle, {
    int daysRange = 14,
  }) {
    DateTime utcStart =
        date.subtract(Duration(days: daysRange)).toUtc(); // 찾기 시작하는 시간
    DateTime utcEnd = date.add(Duration(days: daysRange)).toUtc(); // 찾기 끝나는 시간

    // 100번 반복해서 아주 정확한 시간을 찾을 때까지 범위를 반씩 줄여나가요。
    for (int i = 0; i < 100; i++) {
      if (utcStart.isAtSameMomentAs(utcEnd)) break;
      final mid = utcStart.add(
        Duration(milliseconds: utcEnd.difference(utcStart).inMilliseconds ~/ 2),
      ); // 중간 시간을 찾아요。
      if (mid.isAtSameMomentAs(utcStart) || mid.isAtSameMomentAs(utcEnd)) break;

      final positions = getSunMoonLongitude(mid);
      final sunLon = positions['sun']!;
      final moonLon = positions['moon']!;
      final angle = Sweph.swe_degnorm(
        moonLon - sunLon,
      ); // 중간 시간의 해와 달 각도를 계산해요。

      final delta = Sweph.swe_degnorm(angle - targetAngle);

      // 만약 찾은 각도가 목표 각도와 아주 비슷하면 시간을 알려주고 끝내요。
      if (delta < 0.0005 || delta > 359.9995) {
        return mid;
      }

      // 만약 각도가 목표보다 앞서면 끝나는 시간을 중간으로 바꿔서 범위를 줄여요。
      if (delta < 180) {
        utcEnd = mid;
      } else {
        // 각도가 목표보다 뒤에 있으면 시작 시간을 중간으로 바꿔서 범위를 줄여요。
        utcStart = mid;
      }
    }
    return null; // 못 찾으면 '없어요'라고 알려줘요。
  }

  // 달이 특정 위치(경도)에 도착하는 시간을 찾아주는 숨겨진 함수예요.
  DateTime? _findTimeOfLongitude(
    DateTime start,
    DateTime end,
    double targetLon,
  ) {
    targetLon = Sweph.swe_degnorm(targetLon);
    DateTime utcStart = start.toUtc();
    DateTime utcEnd = end.toUtc();

    double startLon;
    try {
      startLon = Sweph.swe_degnorm(
        getLongitude(HeavenlyBody.SE_MOON, utcStart),
      );
    } catch (e) {
      return null;
    }

    final targetFromStart = (targetLon - startLon + 360) % 360;
    double endLon;
    try {
      endLon = Sweph.swe_degnorm(getLongitude(HeavenlyBody.SE_MOON, utcEnd));
    } catch (e) {
      return null;
    }
    final range = (endLon - startLon + 360) % 360;

    if (targetFromStart > range + 0.1) {
      return null;
    }

    // 100번 반복해서 시간을 아주 정확하게 찾아요。
    for (int i = 0; i < 100; i++) {
      if (utcStart.isAtSameMomentAs(utcEnd)) break;
      final mid = utcStart.add(
        Duration(milliseconds: utcEnd.difference(utcStart).inMilliseconds ~/ 2),
      );
      if (mid.isAtSameMomentAs(utcStart) || mid.isAtSameMomentAs(utcEnd)) break;

      final midLon = Sweph.swe_degnorm(getLongitude(HeavenlyBody.SE_MOON, mid));
      final delta = Sweph.swe_degnorm(midLon - targetLon);

      if (delta < 0.0001 || delta > 359.9999) {
        return mid;
      }

      if (((midLon - startLon + 360) % 360) < targetFromStart) {
        utcStart = mid;
      } else {
        utcEnd = mid;
      }
    }
    return null;
  }

  // 달과 다른 행성 사이의 각도가 정확히 언제 나타나는지 찾아주는 숨겨진 함수예요.
  DateTime? _findExactAspectTime(
    DateTime start,
    DateTime end,
    HeavenlyBody planet,
    double targetDiff,
  ) {
    targetDiff = Sweph.swe_degnorm(targetDiff);
    DateTime utcStart = start.toUtc();
    DateTime utcEnd = end.toUtc();

    double startDiff, endDiff;
    try {
      final startMoonLon = getLongitude(HeavenlyBody.SE_MOON, utcStart);
      final startPlanetLon = getLongitude(planet, utcStart);
      startDiff = Sweph.swe_degnorm(startMoonLon - startPlanetLon);

      final endMoonLon = getLongitude(HeavenlyBody.SE_MOON, utcEnd);
      final endPlanetLon = getLongitude(planet, utcEnd);
      endDiff = Sweph.swe_degnorm(endMoonLon - endPlanetLon);
    } catch (e) {
      return null;
    }

    final range = (endDiff - startDiff + 360) % 360;
    final targetFromStart = (targetDiff - startDiff + 360) % 360;

    if (targetFromStart > range + 0.01) {
      return null;
    }

    // 100번 반복해서 시간을 아주 정확하게 찾아요。
    for (int i = 0; i < 100; i++) {
      if (utcStart.isAtSameMomentAs(utcEnd)) break;
      final mid = utcStart.add(
        Duration(milliseconds: utcEnd.difference(utcStart).inMilliseconds ~/ 2),
      );
      if (mid.isAtSameMomentAs(utcStart) || mid.isAtSameMomentAs(utcEnd)) break;

      final moonLon = getLongitude(HeavenlyBody.SE_MOON, mid);
      final planetLon = getLongitude(planet, mid);
      final midDiff = Sweph.swe_degnorm(moonLon - planetLon);

      final delta = Sweph.swe_degnorm(midDiff - targetDiff);
      if (delta < 0.001 || delta > 359.999) {
        return mid;
      }

      if (((midDiff - startDiff + 360) % 360) < targetFromStart) {
        utcStart = mid;
      } else {
        utcEnd = mid;
      }
    }
    return null;
  }

  // 달이 특정 별자리를 지나기 전에 마지막으로 행성들과 '좋은 만남'을 갖는 시간을 찾아주는 함수예요.
  Map<String, dynamic>? _findLastAspectTime(
    DateTime moonSignEntryTime,
    DateTime moonSignExitTime,
  ) {
    DateTime? lastAspectTime;
    HeavenlyBody? lastAspectPlanet;
    double? lastAspectAngle;

    // 모든 중요한 행성과 중요한 각도를 하나씩 확인해요.
    for (final planet in majorPlanets) {
      for (final aspect in majorAspects) {
        List<double> targets = [aspect];
        if (aspect > 0 && aspect < 180) {
          // 0도, 180도 외에 다른 각도도 반대쪽 각도를 추가해요.
          targets.add(360 - aspect);
        }

        for (final targetDiff in targets) {
          // 달이 별자리에 머무는 시간 동안 각도가 만들어지는지 찾아봐요.
          final aspectTime = _findExactAspectTime(
            moonSignEntryTime,
            moonSignExitTime,
            planet,
            targetDiff,
          );

          if (aspectTime != null) {
            // 가장 마지막에 나타난 각도의 시간을 저장해요.
            if (lastAspectTime == null || aspectTime.isAfter(lastAspectTime)) {
              lastAspectTime = aspectTime;
              lastAspectPlanet = planet;
              lastAspectAngle = aspect; // 원래 각도(0, 60, 90...)를 저장해요.
            }
          }
        }
      }
    }

    if (lastAspectTime != null) {
      return {
        'time': lastAspectTime,
        'planet': lastAspectPlanet,
        'aspect': lastAspectAngle,
      };
    }
    return null;
  }

  // 달이 힘을 잃는 시간(Void-of-Course, 보이드 오브 코스)을 찾아주는 함수예요.
  // 이 시간은 달이 다음 별자리로 가기 전에 다른 행성들과 중요한 만남이 없는 때를 말해요.
  Map<String, dynamic> findVoidOfCoursePeriod(DateTime date) {
    final dayStart =
        date.isUtc
            ? DateTime.utc(date.year, date.month, date.day)
            : DateTime(date.year, date.month, date.day);
    var searchDate = dayStart;

    // 며칠간 반복해서 보이드 오브 코스 시간을 찾아요.
    for (int i = 0; i < 5; i++) {
      final moonSignTimes = getMoonSignTimes(
        searchDate,
      ); // 달이 별자리에 머무는 시간을 가져와요.
      final signStartTime = moonSignTimes['start'];
      final signEndTime = moonSignTimes['end'];

      if (signStartTime == null || signEndTime == null) {
        return {'start': null, 'end': null}; // 시간을 찾지 못하면 포기해요.
      }

      final lastAspectInfo = _findLastAspectTime(
        signStartTime,
        signEndTime,
      ); // 마지막 만남 정보를 찾아봐요.

      DateTime? vocStart;
      String? vocPlanet;
      String? vocAspect;

      if (lastAspectInfo != null) {
        vocStart = lastAspectInfo['time'] as DateTime; // 마지막 만남 이후부터 보이드 시작이에요.
        vocPlanet = getPlanetEmoji(lastAspectInfo['planet'] as HeavenlyBody);
        vocAspect = getAspectEmoji(lastAspectInfo['aspect'] as double);
      } else {
        vocStart = signStartTime; // 만약 마지막 만남이 없으면 별자리에 들어온 순간부터 보이드 시작이에요.
      }
      final vocEnd = signEndTime; // 보이드 끝은 별자리에서 나가는 시간이에요.

      // 만약 오늘 이후에 보이드 오브 코스 시간이 있다면, 그 시간을 알려줘요.
      if (vocEnd.isAfter(date)) {
        return {
          'start': vocStart,
          'end': vocEnd,
          'planet': vocPlanet,
          'aspect': vocAspect,
        };
      }
      // 오늘이 아니면 다음 별자리로 넘어가서 다시 찾아봐요.
      // 1분 추가: 정밀도 오차로 인해 이전 별자리 구간에 갇혀 무한 루프(N/A)가 발생하는 것을 방지
      searchDate = signEndTime.add(const Duration(minutes: 1));
    }
    return {'start': null, 'end': null}; // 5일 내에 못 찾으면 '없어요'라고 알려줘요.
  }

  // 행성 기호를 알려주는 함수예요.
  String getPlanetEmoji(HeavenlyBody planet) {
    final index = majorPlanets.indexOf(planet);
    if (index != -1 && index < planetSigns.length) {
      return planetSigns[index];
    }
    return '';
  }

  // 각도(어스펙트) 기호를 알려주는 함수예요.
  String getAspectEmoji(double aspect) {
    // 360도 넘어가거나 음수인 경우 정규화 (혹시 몰라서)
    // 하지만 여기서는 majorAspects에 있는 값(0, 60, 90, 120, 180)만 들어올 거예요.
    final index = majorAspects.indexOf(aspect);
    if (index != -1 && index < aspectSigns.length) {
      return aspectSigns[index];
    }
    return '';
  }

  // 달의 모양 이름에 맞는 이모티콘을 찾아주는 함수예요.
  String getMoonPhaseEmoji(String moonPhaseName) {
    switch (moonPhaseName) {
      case '🌑 New Moon':
        return '🌑';
      case '🌒 Crescent Moon':
        return '🌒';
      case '🌓 First Quarter':
        return '🌓';
      case '🌔 Gibbous Moon':
        return '🌔';
      case '🌕 Full Moon':
        return '🌕';
      case '🌖 Disseminating Moon':
        return '🌖';
      case '🌗 Last Quarter':
        return '🌗';
      case '🌘 Balsamic Moon':
        return '🌘';
      default:
        return '❓'; // 알 수 없는 이름이면 물음표를 보내요.
    }
  }

  // 달 모양 이름에서 이모티콘을 빼고 글씨만 남기는 함수예요.
  String getMoonPhaseNameOnly(String moonPhaseName) {
    return moonPhaseName.replaceAll(RegExp(r'^\S+\s'), ''); // 이모티콘을 찾아 지워요.
  }

  // 특정 월의 모든 VOC 이벤트를 가져오는 함수
  Map<DateTime, List<Map<String, dynamic>>> getVocEventsForMonth(
      int year, int month) {
    final Map<DateTime, List<Map<String, dynamic>>> events = {};
    // 검색 시작일을 해당 월의 1일 UTC 자정으로 설정
    var searchDate = DateTime.utc(year, month, 1);
    // 검색 종료일을 다음 달 1일 UTC 자정으로 설정
    final monthEnd = DateTime.utc(year, month + 1, 1);

    while (searchDate.isBefore(monthEnd)) {
      // searchDate부터 다음 VOC 기간을 찾음
      final voc = findVoidOfCoursePeriod(searchDate);
      final vocStart = voc['start'] as DateTime?;
      final vocEnd = voc['end'] as DateTime?;

      // vocStart가 없거나, 이미 해당 월을 넘어섰다면 루프 종료
      if (vocStart == null || vocStart.isAfter(monthEnd)) {
        break;
      }

      // VOC 기간이 유효하면, 이벤트를 맵에 추가
      if (vocEnd != null) {
        // VOC가 여러 날에 걸쳐 있을 수 있으므로, 시작일부터 종료일까지 하루씩 순회
        var day = DateTime.utc(vocStart.year, vocStart.month, vocStart.day);
        final lastDay = DateTime.utc(vocEnd.year, vocEnd.month, vocEnd.day);

        while (day.isBefore(lastDay) || day.isAtSameMomentAs(lastDay)) {
          // 해당 날짜에 이벤트 목록이 없으면 새로 생성
          if (events[day] == null) {
            events[day] = [];
          }
          // 이벤트 목록에 현재 VOC 정보 추가
          events[day]!.add(voc);
          // 다음 날로 이동
          day = day.add(const Duration(days: 1));
        }
        // 다음 검색 시작 위치를 현재 찾은 VOC의 종료 시간 1분 뒤로 설정
        // (무한 루프 방지)
        searchDate = vocEnd.add(const Duration(minutes: 1));
      } else {
        // vocEnd가 null이면, 더 이상 진행할 수 없으므로 루프 종료
        break;
      }
    }
    return events;
  }
}
