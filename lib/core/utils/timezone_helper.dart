// 이 파일은 시간대(Timezone) 관련 기능을 도와주는 도우미(Helper) 파일입니다.
// 컴퓨터가 알려주는 시간 정보(예: +9시간)를 사람이 알아보기 쉬운 글자(예: '한국 표준시')로 바꿔주는 역할을 해요.
class TimeZoneHelper {
  // getTimeZoneName 함수는 Duration(시간의 차이)을 입력받아서,
  // 해당하는 시간대의 이름을 글자로 돌려주는 똑똑한 친구예요.
  static String getTimeZoneName(Duration offset) {
    // 만약 세계 표준시(UTC)와의 시간 차이가 정확히 9시간이라면,
    if (offset == const Duration(hours: 9)) {
      // 그건 바로 대한민국이니까 '한국 표준시'라는 글자를 돌려줘요.
      return '한국 표준시';
    }
    // 만약 다른 나라에서 앱을 켠다면, 그 나라의 시간대에 맞게
    // 'UTC+시간' 또는 'UTC-시간' 형태로 보여줘요. (예: UTC+05:30)
    return 'UTC${offset.isNegative ? '' : '+'}${offset.toString().split('.').first.padLeft(8, '0').substring(0, 5)}';
  }
}
