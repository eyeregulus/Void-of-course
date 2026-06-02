import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class TimezoneInfo {
  final String id;
  final String displayNameKo;
  final String displayNameEn;
  final String offsetDisplay;
  final String flag;
  final String countryNameKo;
  final String countryNameEn;
  final String cityNameKo;
  final String cityNameEn;
  final bool isDstCountry; // 서머타임을 시행하는 국가 여부

  const TimezoneInfo({
    required this.id,
    required this.displayNameKo,
    required this.displayNameEn,
    required this.offsetDisplay,
    required this.flag,
    required this.countryNameKo,
    required this.countryNameEn,
    required this.cityNameKo,
    required this.cityNameEn,
    this.isDstCountry = false,
  });

  String getDisplayName(String languageCode) {
    return languageCode == 'ko' ? displayNameKo : displayNameEn;
  }
}

class TimezoneProvider extends ChangeNotifier {
  String _selectedTimezoneId = 'Asia/Seoul';
  bool _isDstApplied = false; // 서머타임 적용 여부

  String get selectedTimezoneId => _selectedTimezoneId;
  bool get isDstApplied => _isDstApplied;

  // 지원하는 타임존 목록 (offsetDisplay는 아스트로 골드 스타일 POSIX 표기법 사용)
  // 국가명(영문) ABC순 정렬, 기본 선택값은 Asia/Seoul
  static const List<TimezoneInfo> supportedTimezones = [
    // ═══════════════════════════════════════════════════════════
    // A
    // ═══════════════════════════════════════════════════════════
    TimezoneInfo(
      id: 'America/Argentina/Buenos_Aires',
      displayNameKo: '아르헨티나 • 부에노스아이레스',
      displayNameEn: 'Argentina • Buenos Aires',
      offsetDisplay: 'ART-3',
      flag: '🇦🇷',
      countryNameKo: '아르헨티나',
      countryNameEn: 'Argentina',
      cityNameKo: '부에노스아이레스',
      cityNameEn: 'Buenos Aires',
      isDstCountry: false,
    ),
    TimezoneInfo(
      id: 'Australia/Sydney',
      displayNameKo: '호주 • 시드니',
      displayNameEn: 'Australia • Sydney',
      offsetDisplay: 'AEST-10',
      flag: '🇦🇺',
      countryNameKo: '호주',
      countryNameEn: 'Australia',
      cityNameKo: '시드니',
      cityNameEn: 'Sydney',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'Europe/Vienna',
      displayNameKo: '오스트리아 • 빈',
      displayNameEn: 'Austria • Vienna',
      offsetDisplay: 'CET-1',
      flag: '🇦🇹',
      countryNameKo: '오스트리아',
      countryNameEn: 'Austria',
      cityNameKo: '빈',
      cityNameEn: 'Vienna',
      isDstCountry: true,
    ),

    // ═══════════════════════════════════════════════════════════
    // B
    // ═══════════════════════════════════════════════════════════
    TimezoneInfo(
      id: 'Europe/Brussels',
      displayNameKo: '벨기에 • 브뤼셀',
      displayNameEn: 'Belgium • Brussels',
      offsetDisplay: 'CET-1',
      flag: '🇧🇪',
      countryNameKo: '벨기에',
      countryNameEn: 'Belgium',
      cityNameKo: '브뤼셀',
      cityNameEn: 'Brussels',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'America/Sao_Paulo',
      displayNameKo: '브라질 • 상파울루',
      displayNameEn: 'Brazil • São Paulo',
      offsetDisplay: 'BRT-3',
      flag: '🇧🇷',
      countryNameKo: '브라질',
      countryNameEn: 'Brazil',
      cityNameKo: '상파울루',
      cityNameEn: 'São Paulo',
      isDstCountry: false,
    ),
    TimezoneInfo(
      id: 'Europe/Sofia',
      displayNameKo: '불가리아 • 소피아',
      displayNameEn: 'Bulgaria • Sofia',
      offsetDisplay: 'EET-2',
      flag: '🇧🇬',
      countryNameKo: '불가리아',
      countryNameEn: 'Bulgaria',
      cityNameKo: '소피아',
      cityNameEn: 'Sofia',
      isDstCountry: true,
    ),

    // ═══════════════════════════════════════════════════════════
    // C
    // ═══════════════════════════════════════════════════════════
    TimezoneInfo(
      id: 'America/Toronto',
      displayNameKo: '캐나다 • 토론토',
      displayNameEn: 'Canada • Toronto',
      offsetDisplay: 'EST+5',
      flag: '🇨🇦',
      countryNameKo: '캐나다',
      countryNameEn: 'Canada',
      cityNameKo: '토론토',
      cityNameEn: 'Toronto',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'America/Vancouver',
      displayNameKo: '캐나다 • 밴쿠버',
      displayNameEn: 'Canada • Vancouver',
      offsetDisplay: 'PST+8',
      flag: '🇨🇦',
      countryNameKo: '캐나다',
      countryNameEn: 'Canada',
      cityNameKo: '밴쿠버',
      cityNameEn: 'Vancouver',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'Asia/Shanghai',
      displayNameKo: '중국 • 상하이',
      displayNameEn: 'China • Shanghai',
      offsetDisplay: 'CST-8',
      flag: '🇨🇳',
      countryNameKo: '중국',
      countryNameEn: 'China',
      cityNameKo: '상하이',
      cityNameEn: 'Shanghai',
      isDstCountry: false,
    ),
    TimezoneInfo(
      id: 'Europe/Zagreb',
      displayNameKo: '크로아티아 • 자그레브',
      displayNameEn: 'Croatia • Zagreb',
      offsetDisplay: 'CET-1',
      flag: '🇭🇷',
      countryNameKo: '크로아티아',
      countryNameEn: 'Croatia',
      cityNameKo: '자그레브',
      cityNameEn: 'Zagreb',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'Europe/Prague',
      displayNameKo: '체코 • 프라하',
      displayNameEn: 'Czechia • Prague',
      offsetDisplay: 'CET-1',
      flag: '🇨🇿',
      countryNameKo: '체코',
      countryNameEn: 'Czechia',
      cityNameKo: '프라하',
      cityNameEn: 'Prague',
      isDstCountry: true,
    ),

    // ═══════════════════════════════════════════════════════════
    // D
    // ═══════════════════════════════════════════════════════════
    TimezoneInfo(
      id: 'Europe/Copenhagen',
      displayNameKo: '덴마크 • 코펜하겐',
      displayNameEn: 'Denmark • Copenhagen',
      offsetDisplay: 'CET-1',
      flag: '🇩🇰',
      countryNameKo: '덴마크',
      countryNameEn: 'Denmark',
      cityNameKo: '코펜하겐',
      cityNameEn: 'Copenhagen',
      isDstCountry: true,
    ),

    // ═══════════════════════════════════════════════════════════
    // E
    // ═══════════════════════════════════════════════════════════
    TimezoneInfo(
      id: 'Africa/Cairo',
      displayNameKo: '이집트 • 카이로',
      displayNameEn: 'Egypt • Cairo',
      offsetDisplay: 'EET-2',
      flag: '🇪🇬',
      countryNameKo: '이집트',
      countryNameEn: 'Egypt',
      cityNameKo: '카이로',
      cityNameEn: 'Cairo',
      isDstCountry: false,
    ),

    // ═══════════════════════════════════════════════════════════
    // F
    // ═══════════════════════════════════════════════════════════
    TimezoneInfo(
      id: 'Europe/Helsinki',
      displayNameKo: '핀란드 • 헬싱키',
      displayNameEn: 'Finland • Helsinki',
      offsetDisplay: 'EET-2',
      flag: '🇫🇮',
      countryNameKo: '핀란드',
      countryNameEn: 'Finland',
      cityNameKo: '헬싱키',
      cityNameEn: 'Helsinki',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'Europe/Paris',
      displayNameKo: '프랑스 • 파리',
      displayNameEn: 'France • Paris',
      offsetDisplay: 'CET-1',
      flag: '🇫🇷',
      countryNameKo: '프랑스',
      countryNameEn: 'France',
      cityNameKo: '파리',
      cityNameEn: 'Paris',
      isDstCountry: true,
    ),

    // ═══════════════════════════════════════════════════════════
    // G
    // ═══════════════════════════════════════════════════════════
    TimezoneInfo(
      id: 'Europe/Berlin',
      displayNameKo: '독일 • 베를린',
      displayNameEn: 'Germany • Berlin',
      offsetDisplay: 'CET-1',
      flag: '🇩🇪',
      countryNameKo: '독일',
      countryNameEn: 'Germany',
      cityNameKo: '베를린',
      cityNameEn: 'Berlin',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'Europe/Athens',
      displayNameKo: '그리스 • 아테네',
      displayNameEn: 'Greece • Athens',
      offsetDisplay: 'EET-2',
      flag: '🇬🇷',
      countryNameKo: '그리스',
      countryNameEn: 'Greece',
      cityNameKo: '아테네',
      cityNameEn: 'Athens',
      isDstCountry: true,
    ),

    // ═══════════════════════════════════════════════════════════
    // H
    // ═══════════════════════════════════════════════════════════
    TimezoneInfo(
      id: 'Asia/Hong_Kong',
      displayNameKo: '홍콩',
      displayNameEn: 'Hong Kong',
      offsetDisplay: 'HKT-8',
      flag: '🇭🇰',
      countryNameKo: '홍콩',
      countryNameEn: 'Hong Kong',
      cityNameKo: '홍콩',
      cityNameEn: 'Hong Kong',
      isDstCountry: false,
    ),
    TimezoneInfo(
      id: 'Europe/Budapest',
      displayNameKo: '헝가리 • 부다페스트',
      displayNameEn: 'Hungary • Budapest',
      offsetDisplay: 'CET-1',
      flag: '🇭🇺',
      countryNameKo: '헝가리',
      countryNameEn: 'Hungary',
      cityNameKo: '부다페스트',
      cityNameEn: 'Budapest',
      isDstCountry: true,
    ),

    // ═══════════════════════════════════════════════════════════
    // I
    // ═══════════════════════════════════════════════════════════
    TimezoneInfo(
      id: 'Asia/Kolkata',
      displayNameKo: '인도 • 콜카타',
      displayNameEn: 'India • Kolkata',
      offsetDisplay: 'IST-5:30',
      flag: '🇮🇳',
      countryNameKo: '인도',
      countryNameEn: 'India',
      cityNameKo: '콜카타',
      cityNameEn: 'Kolkata',
      isDstCountry: false,
    ),
    TimezoneInfo(
      id: 'Europe/Dublin',
      displayNameKo: '아일랜드 • 더블린',
      displayNameEn: 'Ireland • Dublin',
      offsetDisplay: 'GMT 0:00',
      flag: '🇮🇪',
      countryNameKo: '아일랜드',
      countryNameEn: 'Ireland',
      cityNameKo: '더블린',
      cityNameEn: 'Dublin',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'Europe/Rome',
      displayNameKo: '이탈리아 • 로마',
      displayNameEn: 'Italy • Rome',
      offsetDisplay: 'CET-1',
      flag: '🇮🇹',
      countryNameKo: '이탈리아',
      countryNameEn: 'Italy',
      cityNameKo: '로마',
      cityNameEn: 'Rome',
      isDstCountry: true,
    ),

    // ═══════════════════════════════════════════════════════════
    // J
    // ═══════════════════════════════════════════════════════════
    TimezoneInfo(
      id: 'Asia/Tokyo',
      displayNameKo: '일본 • 도쿄',
      displayNameEn: 'Japan • Tokyo',
      offsetDisplay: 'JST-9',
      flag: '🇯🇵',
      countryNameKo: '일본',
      countryNameEn: 'Japan',
      cityNameKo: '도쿄',
      cityNameEn: 'Tokyo',
      isDstCountry: false,
    ),

    // ═══════════════════════════════════════════════════════════
    // M
    // ═══════════════════════════════════════════════════════════
    TimezoneInfo(
      id: 'Asia/Kuala_Lumpur',
      displayNameKo: '말레이시아 • 쿠알라룸푸르',
      displayNameEn: 'Malaysia • Kuala Lumpur',
      offsetDisplay: 'MYT-8',
      flag: '🇲🇾',
      countryNameKo: '말레이시아',
      countryNameEn: 'Malaysia',
      cityNameKo: '쿠알라룸푸르',
      cityNameEn: 'Kuala Lumpur',
      isDstCountry: false,
    ),
    TimezoneInfo(
      id: 'America/Mexico_City',
      displayNameKo: '멕시코 • 멕시코시티',
      displayNameEn: 'Mexico • Mexico City',
      offsetDisplay: 'CST+6',
      flag: '🇲🇽',
      countryNameKo: '멕시코',
      countryNameEn: 'Mexico',
      cityNameKo: '멕시코시티',
      cityNameEn: 'Mexico City',
      isDstCountry: false,
    ),
    TimezoneInfo(
      id: 'Africa/Casablanca',
      displayNameKo: '모로코 • 카사블랑카',
      displayNameEn: 'Morocco • Casablanca',
      offsetDisplay: 'WET-1',
      flag: '🇲🇦',
      countryNameKo: '모로코',
      countryNameEn: 'Morocco',
      cityNameKo: '카사블랑카',
      cityNameEn: 'Casablanca',
      isDstCountry: false,
    ),

    // ═══════════════════════════════════════════════════════════
    // N
    // ═══════════════════════════════════════════════════════════
    TimezoneInfo(
      id: 'Europe/Amsterdam',
      displayNameKo: '네덜란드 • 암스테르담',
      displayNameEn: 'Netherlands • Amsterdam',
      offsetDisplay: 'CET-1',
      flag: '🇳🇱',
      countryNameKo: '네덜란드',
      countryNameEn: 'Netherlands',
      cityNameKo: '암스테르담',
      cityNameEn: 'Amsterdam',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'Pacific/Auckland',
      displayNameKo: '뉴질랜드 • 오클랜드',
      displayNameEn: 'New Zealand • Auckland',
      offsetDisplay: 'NZST-12',
      flag: '🇳🇿',
      countryNameKo: '뉴질랜드',
      countryNameEn: 'New Zealand',
      cityNameKo: '오클랜드',
      cityNameEn: 'Auckland',
      isDstCountry: true,
    ),

    // ═══════════════════════════════════════════════════════════
    // P
    // ═══════════════════════════════════════════════════════════
    TimezoneInfo(
      id: 'Europe/Warsaw',
      displayNameKo: '폴란드 • 바르샤바',
      displayNameEn: 'Poland • Warsaw',
      offsetDisplay: 'CET-1',
      flag: '🇵🇱',
      countryNameKo: '폴란드',
      countryNameEn: 'Poland',
      cityNameKo: '바르샤바',
      cityNameEn: 'Warsaw',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'Europe/Lisbon',
      displayNameKo: '포르투갈 • 리스본',
      displayNameEn: 'Portugal • Lisbon',
      offsetDisplay: 'WET 0:00',
      flag: '🇵🇹',
      countryNameKo: '포르투갈',
      countryNameEn: 'Portugal',
      cityNameKo: '리스본',
      cityNameEn: 'Lisbon',
      isDstCountry: true,
    ),

    // ═══════════════════════════════════════════════════════════
    // R
    // ═══════════════════════════════════════════════════════════
    TimezoneInfo(
      id: 'Europe/Moscow',
      displayNameKo: '러시아 • 모스크바',
      displayNameEn: 'Russia • Moscow',
      offsetDisplay: 'MSK-3',
      flag: '🇷🇺',
      countryNameKo: '러시아',
      countryNameEn: 'Russia',
      cityNameKo: '모스크바',
      cityNameEn: 'Moscow',
      isDstCountry: false,
    ),

    // ═══════════════════════════════════════════════════════════
    // S
    // ═══════════════════════════════════════════════════════════
    TimezoneInfo(
      id: 'Asia/Riyadh',
      displayNameKo: '사우디아라비아 • 리야드',
      displayNameEn: 'Saudi Arabia • Riyadh',
      offsetDisplay: 'AST-3',
      flag: '🇸🇦',
      countryNameKo: '사우디아라비아',
      countryNameEn: 'Saudi Arabia',
      cityNameKo: '리야드',
      cityNameEn: 'Riyadh',
      isDstCountry: false,
    ),
    TimezoneInfo(
      id: 'Asia/Singapore',
      displayNameKo: '싱가포르',
      displayNameEn: 'Singapore',
      offsetDisplay: 'SGT-8',
      flag: '🇸🇬',
      countryNameKo: '싱가포르',
      countryNameEn: 'Singapore',
      cityNameKo: '싱가포르',
      cityNameEn: 'Singapore',
      isDstCountry: false,
    ),
    TimezoneInfo(
      id: 'Africa/Johannesburg',
      displayNameKo: '남아프리카 • 요하네스버그',
      displayNameEn: 'South Africa • Johannesburg',
      offsetDisplay: 'SAST-2',
      flag: '🇿🇦',
      countryNameKo: '남아프리카',
      countryNameEn: 'South Africa',
      cityNameKo: '요하네스버그',
      cityNameEn: 'Johannesburg',
      isDstCountry: false,
    ),
    TimezoneInfo(
      id: 'Asia/Seoul',
      displayNameKo: '한국 • 서울',
      displayNameEn: 'Korea • Seoul',
      offsetDisplay: 'KST-9',
      flag: '🇰🇷',
      countryNameKo: '대한민국',
      countryNameEn: 'South Korea',
      cityNameKo: '서울',
      cityNameEn: 'Seoul',
      isDstCountry: false,
    ),
    TimezoneInfo(
      id: 'Europe/Madrid',
      displayNameKo: '스페인 • 마드리드',
      displayNameEn: 'Spain • Madrid',
      offsetDisplay: 'CET-1',
      flag: '🇪🇸',
      countryNameKo: '스페인',
      countryNameEn: 'Spain',
      cityNameKo: '마드리드',
      cityNameEn: 'Madrid',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'Europe/Stockholm',
      displayNameKo: '스웨덴 • 스톡홀름',
      displayNameEn: 'Sweden • Stockholm',
      offsetDisplay: 'CET-1',
      flag: '🇸🇪',
      countryNameKo: '스웨덴',
      countryNameEn: 'Sweden',
      cityNameKo: '스톡홀름',
      cityNameEn: 'Stockholm',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'Europe/Zurich',
      displayNameKo: '스위스 • 취리히',
      displayNameEn: 'Switzerland • Zurich',
      offsetDisplay: 'CET-1',
      flag: '🇨🇭',
      countryNameKo: '스위스',
      countryNameEn: 'Switzerland',
      cityNameKo: '취리히',
      cityNameEn: 'Zurich',
      isDstCountry: true,
    ),

    // ═══════════════════════════════════════════════════════════
    // T
    // ═══════════════════════════════════════════════════════════
    TimezoneInfo(
      id: 'Asia/Taipei',
      displayNameKo: '대만 • 타이베이',
      displayNameEn: 'Taiwan • Taipei',
      offsetDisplay: 'CST-8',
      flag: '🇹🇼',
      countryNameKo: '대만',
      countryNameEn: 'Taiwan',
      cityNameKo: '타이베이',
      cityNameEn: 'Taipei',
      isDstCountry: false,
    ),
    TimezoneInfo(
      id: 'Asia/Bangkok',
      displayNameKo: '태국 • 방콕',
      displayNameEn: 'Thailand • Bangkok',
      offsetDisplay: 'ICT-7',
      flag: '🇹🇭',
      countryNameKo: '태국',
      countryNameEn: 'Thailand',
      cityNameKo: '방콕',
      cityNameEn: 'Bangkok',
      isDstCountry: false,
    ),
    TimezoneInfo(
      id: 'Europe/Istanbul',
      displayNameKo: '튀르키예 • 이스탄불',
      displayNameEn: 'Turkey • Istanbul',
      offsetDisplay: 'TRT-3',
      flag: '🇹🇷',
      countryNameKo: '튀르키예',
      countryNameEn: 'Turkey',
      cityNameKo: '이스탄불',
      cityNameEn: 'Istanbul',
      isDstCountry: false,
    ),

    // ═══════════════════════════════════════════════════════════
    // U
    // ═══════════════════════════════════════════════════════════
    TimezoneInfo(
      id: 'Asia/Dubai',
      displayNameKo: 'UAE • 두바이',
      displayNameEn: 'UAE • Dubai',
      offsetDisplay: 'GST-4',
      flag: '🇦🇪',
      countryNameKo: 'UAE',
      countryNameEn: 'UAE',
      cityNameKo: '두바이',
      cityNameEn: 'Dubai',
      isDstCountry: false,
    ),
    TimezoneInfo(
      id: 'Europe/Kiev',
      displayNameKo: '우크라이나 • 키이우',
      displayNameEn: 'Ukraine • Kyiv',
      offsetDisplay: 'EET-2',
      flag: '🇺🇦',
      countryNameKo: '우크라이나',
      countryNameEn: 'Ukraine',
      cityNameKo: '키이우',
      cityNameEn: 'Kyiv',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'Europe/London',
      displayNameKo: '영국 • 런던',
      displayNameEn: 'United Kingdom • London',
      offsetDisplay: 'GMT 0:00',
      flag: '🇬🇧',
      countryNameKo: '영국',
      countryNameEn: 'United Kingdom',
      cityNameKo: '런던',
      cityNameEn: 'London',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'America/Anchorage',
      displayNameKo: '미국 • 앵커리지',
      displayNameEn: 'USA • Anchorage',
      offsetDisplay: 'AKST+9',
      flag: '🇺🇸',
      countryNameKo: '미국',
      countryNameEn: 'USA',
      cityNameKo: '앵커리지',
      cityNameEn: 'Anchorage',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'America/Chicago',
      displayNameKo: '미국 • 시카고',
      displayNameEn: 'USA • Chicago',
      offsetDisplay: 'CST+6',
      flag: '🇺🇸',
      countryNameKo: '미국',
      countryNameEn: 'USA',
      cityNameKo: '시카고',
      cityNameEn: 'Chicago',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'America/Denver',
      displayNameKo: '미국 • 덴버',
      displayNameEn: 'USA • Denver',
      offsetDisplay: 'MST+7',
      flag: '🇺🇸',
      countryNameKo: '미국',
      countryNameEn: 'USA',
      cityNameKo: '덴버',
      cityNameEn: 'Denver',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'Pacific/Honolulu',
      displayNameKo: '미국 • 하와이',
      displayNameEn: 'USA • Hawaii',
      offsetDisplay: 'HST+10',
      flag: '🇺🇸',
      countryNameKo: '미국',
      countryNameEn: 'USA',
      cityNameKo: '하와이',
      cityNameEn: 'Hawaii',
      isDstCountry: false,
    ),
    TimezoneInfo(
      id: 'America/Los_Angeles',
      displayNameKo: '미국 • 로스앤젤레스',
      displayNameEn: 'USA • Los Angeles',
      offsetDisplay: 'PST+8',
      flag: '🇺🇸',
      countryNameKo: '미국',
      countryNameEn: 'USA',
      cityNameKo: '로스앤젤레스',
      cityNameEn: 'Los Angeles',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'America/New_York',
      displayNameKo: '미국 • 뉴욕',
      displayNameEn: 'USA • New York',
      offsetDisplay: 'EST+5',
      flag: '🇺🇸',
      countryNameKo: '미국',
      countryNameEn: 'USA',
      cityNameKo: '뉴욕',
      cityNameEn: 'New York',
      isDstCountry: true,
    ),
    TimezoneInfo(
      id: 'America/Phoenix',
      displayNameKo: '미국 • 피닉스',
      displayNameEn: 'USA • Phoenix',
      offsetDisplay: 'MST+7',
      flag: '🇺🇸',
      countryNameKo: '미국',
      countryNameEn: 'USA',
      cityNameKo: '피닉스',
      cityNameEn: 'Phoenix',
      isDstCountry: false,
    ),

    // ═══════════════════════════════════════════════════════════
    // V
    // ═══════════════════════════════════════════════════════════
    TimezoneInfo(
      id: 'Asia/Ho_Chi_Minh',
      displayNameKo: '베트남 • 호찌민시',
      displayNameEn: 'Vietnam • Ho Chi Minh City',
      offsetDisplay: 'ICT-7',
      flag: '🇻🇳',
      countryNameKo: '베트남',
      countryNameEn: 'Vietnam',
      cityNameKo: '호찌민',
      cityNameEn: 'Ho Chi Minh',
      isDstCountry: false,
    ),
  ];

  TimezoneProvider() {
    loadTimezone();
  }

  Future<void> loadTimezone() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedTimezoneId = prefs.getString('selected_timezone') ?? 'Asia/Seoul';
    _isDstApplied = prefs.getBool('is_dst_applied') ?? false;
    notifyListeners();
  }

  Future<void> setTimezone(String timezoneId) async {
    if (_selectedTimezoneId == timezoneId) return;
    _selectedTimezoneId = timezoneId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_timezone', timezoneId);
    notifyListeners();
  }

  /// UTC DateTime을 선택된 타임존으로 변환 (서머타임 수동 토글 반영)
  DateTime convert(DateTime dateTime) {
    try {
      final location = tz.getLocation(_selectedTimezoneId);
      final utcTime = dateTime.toUtc();

      // tz 라이브러리를 통해 UTC를 해당 타임존의 시간으로 변환
      // 이 객체는 해당 날짜에 DST가 적용되는지에 대한 정보(isDst)를 포함
      final tzDateTime = tz.TZDateTime.from(utcTime, location);

      // isDst 정보가 없는 순수한 DateTime 객체 생성
      DateTime baseLocalTime = DateTime(
        tzDateTime.year,
        tzDateTime.month,
        tzDateTime.day,
        tzDateTime.hour,
        tzDateTime.minute,
        tzDateTime.second,
      );

      final tzInfo = currentTimezoneInfo;
      // 서머타임을 적용하지 않는 국가이면, 변환된 시간을 그대로 반환
      if (tzInfo == null || !tzInfo.isDstCountry) {
        return baseLocalTime;
      }

      // 서머타임 적용 국가일 경우, 사용자의 수동 토글과 라이브러리의 자동 적용 상태를 비교하여 보정
      final bool isLibraryApplyingDst = tzDateTime.timeZone.isDst;
      final bool isUserApplyingDst = _isDstApplied;

      if (isUserApplyingDst && !isLibraryApplyingDst) {
        // 사용자는 DST 적용을 원하지만, 라이브러리는 적용하지 않은 경우 (예: 겨울철) -> 1시간 추가
        return baseLocalTime.add(const Duration(hours: 1));
      } else if (!isUserApplyingDst && isLibraryApplyingDst) {
        // 사용자는 DST 적용을 원하지 않지만, 라이브러리는 적용한 경우 (예: 여름철) -> 1시간 빼기
        return baseLocalTime.subtract(const Duration(hours: 1));
      } else {
        // 두 상태가 일치하는 경우 (둘 다 적용 or 둘 다 미적용), 보정 불필요
        return baseLocalTime;
      }
    } catch (e) {
      // 타임존 데이터를 찾지 못하는 등 예외 발생 시, 기기 로컬 시간으로 대체
      return dateTime.toLocal();
    }
  }

  /// 현재 선택된 타임존 정보 가져오기
  TimezoneInfo? get currentTimezoneInfo {
    try {
      return supportedTimezones.firstWhere((tz) => tz.id == _selectedTimezoneId);
    } catch (e) {
      return supportedTimezones.first;
    }
  }

  /// 서머타임 토글
  Future<void> toggleDst() async {
    _isDstApplied = !_isDstApplied;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dst_applied', _isDstApplied);
    notifyListeners();
  }

  /// 서머타임 설정
  Future<void> setDst(bool value) async {
    if (_isDstApplied == value) return;
    _isDstApplied = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dst_applied', _isDstApplied);
    notifyListeners();
  }

  /// 현재 적용된 오프셋 가져오기 (서머타임 포함)
  String getDisplayOffset() {
    final tzInfo = currentTimezoneInfo;
    if (tzInfo == null) return '';

    if (!tzInfo.isDstCountry || !_isDstApplied) {
      return tzInfo.offsetDisplay;
    }

    String offset = tzInfo.offsetDisplay;
    try {
      // 형식 1: "ABBR[+-]N" 또는 "ABBR[+-]N:MM" (예: "CET-1", "PST+8", "IST-5:30")
      final match = RegExp(r'^([A-Z]+)([+-])(\d+)(?::(\d+))?$').firstMatch(offset);

      if (match != null) {
        final abbr = match.group(1)!;
        final sign = match.group(2)!;
        int hours = int.parse(match.group(3)!);
        final minutes = match.group(4);

        // POSIX 규약에서 서머타임 적용:
        // '-' (UTC 동쪽): POSIX 숫자 증가 (CET-1 → CEST-2)
        // '+' (UTC 서쪽): POSIX 숫자 감소 (EST+5 → EDT+4)
        if (sign == '-') {
          hours += 1;
        } else {
          hours -= 1;
        }

        final dstAbbr = _getDstAbbreviation(abbr);
        final minutesPart = (minutes != null) ? ':$minutes' : '';

        if (hours == 0 && (minutes == null || minutes == '00')) {
          return '$dstAbbr 0:00';
        }
        return '$dstAbbr$sign$hours$minutesPart';
      }

      // 형식 2: "ABBR 0:00" (예: "GMT 0:00", "WET 0:00")
      final zeroMatch = RegExp(r'^([A-Z]+)\s+0:00$').firstMatch(offset);
      if (zeroMatch != null) {
        final abbr = zeroMatch.group(1)!;
        final dstAbbr = _getDstAbbreviation(abbr);
        // UTC+0 → 서머타임 UTC+1 → POSIX: -1
        return '$dstAbbr-1';
      }

      return offset;
    } catch (e) {
      return offset;
    }
  }

  /// 약어를 서머타임 약어로 변환
  static String _getDstAbbreviation(String abbr) {
    // 'S' (Standard) 포함 → 'D' (Daylight)로 교체
    // CST→CDT, EST→EDT, PST→PDT, AEST→AEDT, NZST→NZDT, AKST→AKDT
    if (abbr.contains('S')) {
      return abbr.replaceFirst('S', 'D');
    }
    // 'T'로 끝나지만 'S' 없음 → 'T' 앞에 'S' 삽입 (Summer)
    // CET→CEST, EET→EEST, WET→WEST, GMT→GMST, TRT→TRST, BRT→BRST
    if (abbr.endsWith('T')) {
      return '${abbr.substring(0, abbr.length - 1)}ST';
    }
    return abbr;
  }
}
