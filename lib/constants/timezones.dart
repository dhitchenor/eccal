// IANA Timezone Database with Offset Information
// ==============================================
// - organized by region with category headers.
// - contains timezone offset data
// - contains headers, which are marked for organization
// - generates the UI list automatically


// Timezone data with UTC offsets
class TimezoneData {
  final String tzid;
  final String standardName;
  final String standardOffset;
  final String? daylightName;
  final String? daylightOffset;
  
  const TimezoneData({
    required this.tzid,
    required this.standardName,
    required this.standardOffset,
    this.daylightName,
    this.daylightOffset,
  });
}

// TIMEZONE OFFSET DATA
// ====================

// Timezone offset data for generating VTIMEZONE components
// This is the ONLY place timezones need to be added/maintained
const Map<String, TimezoneData> timezoneOffsets = {
  // UTC
  'UTC': TimezoneData(
    tzid: 'UTC',
    standardName: 'UTC',
    standardOffset: '+0000',
  ),
  
  // ========== AFRICA ==========
  'Africa/Abidjan': TimezoneData(
    tzid: 'Africa/Abidjan',
    standardName: 'GMT',
    standardOffset: '+0000',
  ),
  'Africa/Accra': TimezoneData(
    tzid: 'Africa/Accra',
    standardName: 'GMT',
    standardOffset: '+0000',
  ),
  'Africa/Algiers': TimezoneData(
    tzid: 'Africa/Algiers',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Africa/Asmara': TimezoneData(
    tzid: 'Africa/Asmara',
    standardName: 'EAT',
    standardOffset: '+0300',
  ),
  'Africa/Bamako': TimezoneData(
    tzid: 'Africa/Bamako',
    standardName: 'GMT',
    standardOffset: '+0000',
  ),
  'Africa/Bangui': TimezoneData(
    tzid: 'Africa/Bangui',
    standardName: 'WAT',
    standardOffset: '+0100',
  ),
  'Africa/Banjul': TimezoneData(
    tzid: 'Africa/Banjul',
    standardName: 'GMT',
    standardOffset: '+0000',
  ),
  'Africa/Bissau': TimezoneData(
    tzid: 'Africa/Bissau',
    standardName: 'GMT',
    standardOffset: '+0000',
  ),
  'Africa/Blantyre': TimezoneData(
    tzid: 'Africa/Blantyre',
    standardName: 'CAT',
    standardOffset: '+0200',
  ),
  'Africa/Brazzaville': TimezoneData(
    tzid: 'Africa/Brazzaville',
    standardName: 'WAT',
    standardOffset: '+0100',
  ),
  'Africa/Bujumbura': TimezoneData(
    tzid: 'Africa/Bujumbura',
    standardName: 'CAT',
    standardOffset: '+0200',
  ),
  'Africa/Cairo': TimezoneData(
    tzid: 'Africa/Cairo',
    standardName: 'EET',
    standardOffset: '+0200',
  ),
  'Africa/Casablanca': TimezoneData(
    tzid: 'Africa/Casablanca',
    standardName: 'WET',
    standardOffset: '+0000',
  ),
  'Africa/Ceuta': TimezoneData(
    tzid: 'Africa/Ceuta',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Africa/Conakry': TimezoneData(
    tzid: 'Africa/Conakry',
    standardName: 'GMT',
    standardOffset: '+0000',
  ),
  'Africa/Dakar': TimezoneData(
    tzid: 'Africa/Dakar',
    standardName: 'GMT',
    standardOffset: '+0000',
  ),
  'Africa/Dar_es_Salaam': TimezoneData(
    tzid: 'Africa/Dar_es_Salaam',
    standardName: 'EAT',
    standardOffset: '+0300',
  ),
  'Africa/Djibouti': TimezoneData(
    tzid: 'Africa/Djibouti',
    standardName: 'EAT',
    standardOffset: '+0300',
  ),
  'Africa/Douala': TimezoneData(
    tzid: 'Africa/Douala',
    standardName: 'WAT',
    standardOffset: '+0100',
  ),
  'Africa/El_Aaiun': TimezoneData(
    tzid: 'Africa/El_Aaiun',
    standardName: 'WET',
    standardOffset: '+0000',
  ),
  'Africa/Freetown': TimezoneData(
    tzid: 'Africa/Freetown',
    standardName: 'GMT',
    standardOffset: '+0000',
  ),
  'Africa/Gaborone': TimezoneData(
    tzid: 'Africa/Gaborone',
    standardName: 'CAT',
    standardOffset: '+0200',
  ),
  'Africa/Harare': TimezoneData(
    tzid: 'Africa/Harare',
    standardName: 'CAT',
    standardOffset: '+0200',
  ),
  'Africa/Johannesburg': TimezoneData(
    tzid: 'Africa/Johannesburg',
    standardName: 'SAST',
    standardOffset: '+0200',
  ),
  'Africa/Juba': TimezoneData(
    tzid: 'Africa/Juba',
    standardName: 'EAT',
    standardOffset: '+0300',
  ),
  'Africa/Kampala': TimezoneData(
    tzid: 'Africa/Kampala',
    standardName: 'EAT',
    standardOffset: '+0300',
  ),
  'Africa/Khartoum': TimezoneData(
    tzid: 'Africa/Khartoum',
    standardName: 'CAT',
    standardOffset: '+0200',
  ),
  'Africa/Kigali': TimezoneData(
    tzid: 'Africa/Kigali',
    standardName: 'CAT',
    standardOffset: '+0200',
  ),
  'Africa/Kinshasa': TimezoneData(
    tzid: 'Africa/Kinshasa',
    standardName: 'WAT',
    standardOffset: '+0100',
  ),
  'Africa/Lagos': TimezoneData(
    tzid: 'Africa/Lagos',
    standardName: 'WAT',
    standardOffset: '+0100',
  ),
  'Africa/Libreville': TimezoneData(
    tzid: 'Africa/Libreville',
    standardName: 'WAT',
    standardOffset: '+0100',
  ),
  'Africa/Lome': TimezoneData(
    tzid: 'Africa/Lome',
    standardName: 'GMT',
    standardOffset: '+0000',
  ),
  'Africa/Luanda': TimezoneData(
    tzid: 'Africa/Luanda',
    standardName: 'WAT',
    standardOffset: '+0100',
  ),
  'Africa/Lubumbashi': TimezoneData(
    tzid: 'Africa/Lubumbashi',
    standardName: 'CAT',
    standardOffset: '+0200',
  ),
  'Africa/Lusaka': TimezoneData(
    tzid: 'Africa/Lusaka',
    standardName: 'CAT',
    standardOffset: '+0200',
  ),
  'Africa/Malabo': TimezoneData(
    tzid: 'Africa/Malabo',
    standardName: 'WAT',
    standardOffset: '+0100',
  ),
  'Africa/Maputo': TimezoneData(
    tzid: 'Africa/Maputo',
    standardName: 'CAT',
    standardOffset: '+0200',
  ),
  'Africa/Maseru': TimezoneData(
    tzid: 'Africa/Maseru',
    standardName: 'SAST',
    standardOffset: '+0200',
  ),
  'Africa/Mbabane': TimezoneData(
    tzid: 'Africa/Mbabane',
    standardName: 'SAST',
    standardOffset: '+0200',
  ),
  'Africa/Mogadishu': TimezoneData(
    tzid: 'Africa/Mogadishu',
    standardName: 'EAT',
    standardOffset: '+0300',
  ),
  'Africa/Monrovia': TimezoneData(
    tzid: 'Africa/Monrovia',
    standardName: 'GMT',
    standardOffset: '+0000',
  ),
  'Africa/Nairobi': TimezoneData(
    tzid: 'Africa/Nairobi',
    standardName: 'EAT',
    standardOffset: '+0300',
  ),
  'Africa/Ndjamena': TimezoneData(
    tzid: 'Africa/Ndjamena',
    standardName: 'WAT',
    standardOffset: '+0100',
  ),
  'Africa/Niamey': TimezoneData(
    tzid: 'Africa/Niamey',
    standardName: 'WAT',
    standardOffset: '+0100',
  ),
  'Africa/Nouakchott': TimezoneData(
    tzid: 'Africa/Nouakchott',
    standardName: 'GMT',
    standardOffset: '+0000',
  ),
  'Africa/Ouagadougou': TimezoneData(
    tzid: 'Africa/Ouagadougou',
    standardName: 'GMT',
    standardOffset: '+0000',
  ),
  'Africa/Porto-Novo': TimezoneData(
    tzid: 'Africa/Porto-Novo',
    standardName: 'WAT',
    standardOffset: '+0100',
  ),
  'Africa/Sao_Tome': TimezoneData(
    tzid: 'Africa/Sao_Tome',
    standardName: 'GMT',
    standardOffset: '+0000',
  ),
  'Africa/Tripoli': TimezoneData(
    tzid: 'Africa/Tripoli',
    standardName: 'EET',
    standardOffset: '+0200',
  ),
  'Africa/Tunis': TimezoneData(
    tzid: 'Africa/Tunis',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Africa/Windhoek': TimezoneData(
    tzid: 'Africa/Windhoek',
    standardName: 'CAT',
    standardOffset: '+0200',
  ),
  
  // ========== AMERICAS ==========
  'America/Adak': TimezoneData(
    tzid: 'America/Adak',
    standardName: 'HST',
    standardOffset: '-1000',
  ),
  'America/Anchorage': TimezoneData(
    tzid: 'America/Anchorage',
    standardName: 'AKST',
    standardOffset: '-0900',
  ),
  'America/Anguilla': TimezoneData(
    tzid: 'America/Anguilla',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Antigua': TimezoneData(
    tzid: 'America/Antigua',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Araguaina': TimezoneData(
    tzid: 'America/Araguaina',
    standardName: 'BRT',
    standardOffset: '-0300',
  ),
  'America/Argentina/Buenos_Aires': TimezoneData(
    tzid: 'America/Argentina/Buenos_Aires',
    standardName: 'ART',
    standardOffset: '-0300',
  ),
  'America/Argentina/Catamarca': TimezoneData(
    tzid: 'America/Argentina/Catamarca',
    standardName: 'ART',
    standardOffset: '-0300',
  ),
  'America/Argentina/Cordoba': TimezoneData(
    tzid: 'America/Argentina/Cordoba',
    standardName: 'ART',
    standardOffset: '-0300',
  ),
  'America/Argentina/Jujuy': TimezoneData(
    tzid: 'America/Argentina/Jujuy',
    standardName: 'ART',
    standardOffset: '-0300',
  ),
  'America/Argentina/La_Rioja': TimezoneData(
    tzid: 'America/Argentina/La_Rioja',
    standardName: 'ART',
    standardOffset: '-0300',
  ),
  'America/Argentina/Mendoza': TimezoneData(
    tzid: 'America/Argentina/Mendoza',
    standardName: 'ART',
    standardOffset: '-0300',
  ),
  'America/Argentina/Rio_Gallegos': TimezoneData(
    tzid: 'America/Argentina/Rio_Gallegos',
    standardName: 'ART',
    standardOffset: '-0300',
  ),
  'America/Argentina/Salta': TimezoneData(
    tzid: 'America/Argentina/Salta',
    standardName: 'ART',
    standardOffset: '-0300',
  ),
  'America/Argentina/San_Juan': TimezoneData(
    tzid: 'America/Argentina/San_Juan',
    standardName: 'ART',
    standardOffset: '-0300',
  ),
  'America/Argentina/San_Luis': TimezoneData(
    tzid: 'America/Argentina/San_Luis',
    standardName: 'ART',
    standardOffset: '-0300',
  ),
  'America/Argentina/Tucuman': TimezoneData(
    tzid: 'America/Argentina/Tucuman',
    standardName: 'ART',
    standardOffset: '-0300',
  ),
  'America/Argentina/Ushuaia': TimezoneData(
    tzid: 'America/Argentina/Ushuaia',
    standardName: 'ART',
    standardOffset: '-0300',
  ),
  'America/Aruba': TimezoneData(
    tzid: 'America/Aruba',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Asuncion': TimezoneData(
    tzid: 'America/Asuncion',
    standardName: 'PYT',
    standardOffset: '-0400',
  ),
  'America/Atikokan': TimezoneData(
    tzid: 'America/Atikokan',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Bahia': TimezoneData(
    tzid: 'America/Bahia',
    standardName: 'BRT',
    standardOffset: '-0300',
  ),
  'America/Bahia_Banderas': TimezoneData(
    tzid: 'America/Bahia_Banderas',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Barbados': TimezoneData(
    tzid: 'America/Barbados',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Belem': TimezoneData(
    tzid: 'America/Belem',
    standardName: 'BRT',
    standardOffset: '-0300',
  ),
  'America/Belize': TimezoneData(
    tzid: 'America/Belize',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Blanc-Sablon': TimezoneData(
    tzid: 'America/Blanc-Sablon',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Boa_Vista': TimezoneData(
    tzid: 'America/Boa_Vista',
    standardName: 'AMT',
    standardOffset: '-0400',
  ),
  'America/Bogota': TimezoneData(
    tzid: 'America/Bogota',
    standardName: 'COT',
    standardOffset: '-0500',
  ),
  'America/Boise': TimezoneData(
    tzid: 'America/Boise',
    standardName: 'MST',
    standardOffset: '-0700',
  ),
  'America/Cambridge_Bay': TimezoneData(
    tzid: 'America/Cambridge_Bay',
    standardName: 'MST',
    standardOffset: '-0700',
  ),
  'America/Campo_Grande': TimezoneData(
    tzid: 'America/Campo_Grande',
    standardName: 'AMT',
    standardOffset: '-0400',
  ),
  'America/Cancun': TimezoneData(
    tzid: 'America/Cancun',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Caracas': TimezoneData(
    tzid: 'America/Caracas',
    standardName: 'VET',
    standardOffset: '-0400',
  ),
  'America/Cayenne': TimezoneData(
    tzid: 'America/Cayenne',
    standardName: 'GFT',
    standardOffset: '-0300',
  ),
  'America/Cayman': TimezoneData(
    tzid: 'America/Cayman',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Chicago': TimezoneData(
    tzid: 'America/Chicago',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Chihuahua': TimezoneData(
    tzid: 'America/Chihuahua',
    standardName: 'MST',
    standardOffset: '-0700',
  ),
  'America/Ciudad_Juarez': TimezoneData(
    tzid: 'America/Ciudad_Juarez',
    standardName: 'MST',
    standardOffset: '-0700',
  ),
  'America/Costa_Rica': TimezoneData(
    tzid: 'America/Costa_Rica',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Creston': TimezoneData(
    tzid: 'America/Creston',
    standardName: 'MST',
    standardOffset: '-0700',
  ),
  'America/Cuiaba': TimezoneData(
    tzid: 'America/Cuiaba',
    standardName: 'AMT',
    standardOffset: '-0400',
  ),
  'America/Curacao': TimezoneData(
    tzid: 'America/Curacao',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Dawson': TimezoneData(
    tzid: 'America/Dawson',
    standardName: 'MST',
    standardOffset: '-0700',
  ),
  'America/Dawson_Creek': TimezoneData(
    tzid: 'America/Dawson_Creek',
    standardName: 'MST',
    standardOffset: '-0700',
  ),
  'America/Denver': TimezoneData(
    tzid: 'America/Denver',
    standardName: 'MST',
    standardOffset: '-0700',
  ),
  'America/Detroit': TimezoneData(
    tzid: 'America/Detroit',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Dominica': TimezoneData(
    tzid: 'America/Dominica',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Edmonton': TimezoneData(
    tzid: 'America/Edmonton',
    standardName: 'MST',
    standardOffset: '-0700',
  ),
  'America/Eirunepe': TimezoneData(
    tzid: 'America/Eirunepe',
    standardName: 'ACT',
    standardOffset: '-0500',
  ),
  'America/El_Salvador': TimezoneData(
    tzid: 'America/El_Salvador',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Fort_Nelson': TimezoneData(
    tzid: 'America/Fort_Nelson',
    standardName: 'MST',
    standardOffset: '-0700',
  ),
  'America/Fortaleza': TimezoneData(
    tzid: 'America/Fortaleza',
    standardName: 'BRT',
    standardOffset: '-0300',
  ),
  'America/Glace_Bay': TimezoneData(
    tzid: 'America/Glace_Bay',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Goose_Bay': TimezoneData(
    tzid: 'America/Goose_Bay',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Grand_Turk': TimezoneData(
    tzid: 'America/Grand_Turk',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Grenada': TimezoneData(
    tzid: 'America/Grenada',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Guadeloupe': TimezoneData(
    tzid: 'America/Guadeloupe',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Guatemala': TimezoneData(
    tzid: 'America/Guatemala',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Guayaquil': TimezoneData(
    tzid: 'America/Guayaquil',
    standardName: 'ECT',
    standardOffset: '-0500',
  ),
  'America/Guyana': TimezoneData(
    tzid: 'America/Guyana',
    standardName: 'GYT',
    standardOffset: '-0400',
  ),
  'America/Halifax': TimezoneData(
    tzid: 'America/Halifax',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Havana': TimezoneData(
    tzid: 'America/Havana',
    standardName: 'CST',
    standardOffset: '-0500',
  ),
  'America/Hermosillo': TimezoneData(
    tzid: 'America/Hermosillo',
    standardName: 'MST',
    standardOffset: '-0700',
  ),
  'America/Indiana/Indianapolis': TimezoneData(
    tzid: 'America/Indiana/Indianapolis',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Indiana/Knox': TimezoneData(
    tzid: 'America/Indiana/Knox',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Indiana/Marengo': TimezoneData(
    tzid: 'America/Indiana/Marengo',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Indiana/Petersburg': TimezoneData(
    tzid: 'America/Indiana/Petersburg',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Indiana/Tell_City': TimezoneData(
    tzid: 'America/Indiana/Tell_City',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Indiana/Vevay': TimezoneData(
    tzid: 'America/Indiana/Vevay',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Indiana/Vincennes': TimezoneData(
    tzid: 'America/Indiana/Vincennes',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Indiana/Winamac': TimezoneData(
    tzid: 'America/Indiana/Winamac',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Inuvik': TimezoneData(
    tzid: 'America/Inuvik',
    standardName: 'MST',
    standardOffset: '-0700',
  ),
  'America/Iqaluit': TimezoneData(
    tzid: 'America/Iqaluit',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Jamaica': TimezoneData(
    tzid: 'America/Jamaica',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Juneau': TimezoneData(
    tzid: 'America/Juneau',
    standardName: 'AKST',
    standardOffset: '-0900',
  ),
  'America/Kentucky/Louisville': TimezoneData(
    tzid: 'America/Kentucky/Louisville',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Kentucky/Monticello': TimezoneData(
    tzid: 'America/Kentucky/Monticello',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Kralendijk': TimezoneData(
    tzid: 'America/Kralendijk',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/La_Paz': TimezoneData(
    tzid: 'America/La_Paz',
    standardName: 'BOT',
    standardOffset: '-0400',
  ),
  'America/Lima': TimezoneData(
    tzid: 'America/Lima',
    standardName: 'PET',
    standardOffset: '-0500',
  ),
  'America/Los_Angeles': TimezoneData(
    tzid: 'America/Los_Angeles',
    standardName: 'PST',
    standardOffset: '-0800',
  ),
  'America/Lower_Princes': TimezoneData(
    tzid: 'America/Lower_Princes',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Maceio': TimezoneData(
    tzid: 'America/Maceio',
    standardName: 'BRT',
    standardOffset: '-0300',
  ),
  'America/Managua': TimezoneData(
    tzid: 'America/Managua',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Manaus': TimezoneData(
    tzid: 'America/Manaus',
    standardName: 'AMT',
    standardOffset: '-0400',
  ),
  'America/Marigot': TimezoneData(
    tzid: 'America/Marigot',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Martinique': TimezoneData(
    tzid: 'America/Martinique',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Matamoros': TimezoneData(
    tzid: 'America/Matamoros',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Mazatlan': TimezoneData(
    tzid: 'America/Mazatlan',
    standardName: 'MST',
    standardOffset: '-0700',
  ),
  'America/Menominee': TimezoneData(
    tzid: 'America/Menominee',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Merida': TimezoneData(
    tzid: 'America/Merida',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Metlakatla': TimezoneData(
    tzid: 'America/Metlakatla',
    standardName: 'AKST',
    standardOffset: '-0900',
  ),
  'America/Mexico_City': TimezoneData(
    tzid: 'America/Mexico_City',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Miquelon': TimezoneData(
    tzid: 'America/Miquelon',
    standardName: 'PMST',
    standardOffset: '-0300',
  ),
  'America/Moncton': TimezoneData(
    tzid: 'America/Moncton',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Monterrey': TimezoneData(
    tzid: 'America/Monterrey',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Montevideo': TimezoneData(
    tzid: 'America/Montevideo',
    standardName: 'UYT',
    standardOffset: '-0300',
  ),
  'America/Montserrat': TimezoneData(
    tzid: 'America/Montserrat',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Nassau': TimezoneData(
    tzid: 'America/Nassau',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/New_York': TimezoneData(
    tzid: 'America/New_York',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Nome': TimezoneData(
    tzid: 'America/Nome',
    standardName: 'AKST',
    standardOffset: '-0900',
  ),
  'America/Noronha': TimezoneData(
    tzid: 'America/Noronha',
    standardName: 'FNT',
    standardOffset: '-0200',
  ),
  'America/North_Dakota/Beulah': TimezoneData(
    tzid: 'America/North_Dakota/Beulah',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/North_Dakota/Center': TimezoneData(
    tzid: 'America/North_Dakota/Center',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/North_Dakota/New_Salem': TimezoneData(
    tzid: 'America/North_Dakota/New_Salem',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Nuuk': TimezoneData(
    tzid: 'America/Nuuk',
    standardName: 'WGT',
    standardOffset: '-0300',
  ),
  'America/Ojinaga': TimezoneData(
    tzid: 'America/Ojinaga',
    standardName: 'MST',
    standardOffset: '-0700',
  ),
  'America/Panama': TimezoneData(
    tzid: 'America/Panama',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Paramaribo': TimezoneData(
    tzid: 'America/Paramaribo',
    standardName: 'SRT',
    standardOffset: '-0300',
  ),
  'America/Phoenix': TimezoneData(
    tzid: 'America/Phoenix',
    standardName: 'MST',
    standardOffset: '-0700',
  ),
  'America/Port-au,-Prince': TimezoneData(
    tzid: 'America/Port-au,-Prince',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Port_of_Spain': TimezoneData(
    tzid: 'America/Port_of_Spain',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Porto_Velho': TimezoneData(
    tzid: 'America/Porto_Velho',
    standardName: 'AMT',
    standardOffset: '-0400',
  ),
  'America/Puerto_Rico': TimezoneData(
    tzid: 'America/Puerto_Rico',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Punta_Arenas': TimezoneData(
    tzid: 'America/Punta_Arenas',
    standardName: 'CLT',
    standardOffset: '-0400',
  ),
  'America/Rankin_Inlet': TimezoneData(
    tzid: 'America/Rankin_Inlet',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Recife': TimezoneData(
    tzid: 'America/Recife',
    standardName: 'BRT',
    standardOffset: '-0300',
  ),
  'America/Regina': TimezoneData(
    tzid: 'America/Regina',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Resolute': TimezoneData(
    tzid: 'America/Resolute',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Rio_Branco': TimezoneData(
    tzid: 'America/Rio_Branco',
    standardName: 'ACT',
    standardOffset: '-0500',
  ),
  'America/Santarem': TimezoneData(
    tzid: 'America/Santarem',
    standardName: 'BRT',
    standardOffset: '-0300',
  ),
  'America/Santiago': TimezoneData(
    tzid: 'America/Santiago',
    standardName: 'CLT',
    standardOffset: '-0400',
  ),
  'America/Santo_Domingo': TimezoneData(
    tzid: 'America/Santo_Domingo',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Sao_Paulo': TimezoneData(
    tzid: 'America/Sao_Paulo',
    standardName: 'BRT',
    standardOffset: '-0300',
  ),
  'America/Scoresbysund': TimezoneData(
    tzid: 'America/Scoresbysund',
    standardName: 'EGT',
    standardOffset: '-0100',
  ),
  'America/Sitka': TimezoneData(
    tzid: 'America/Sitka',
    standardName: 'AKST',
    standardOffset: '-0900',
  ),
  'America/St_Barthelemy': TimezoneData(
    tzid: 'America/St_Barthelemy',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/St_Johns': TimezoneData(
    tzid: 'America/St_Johns',
    standardName: 'NST',
    standardOffset: '-0330',
  ),
  'America/St_Kitts': TimezoneData(
    tzid: 'America/St_Kitts',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/St_Lucia': TimezoneData(
    tzid: 'America/St_Lucia',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/St_Thomas': TimezoneData(
    tzid: 'America/St_Thomas',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/St_Vincent': TimezoneData(
    tzid: 'America/St_Vincent',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Swift_Current': TimezoneData(
    tzid: 'America/Swift_Current',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Tegucigalpa': TimezoneData(
    tzid: 'America/Tegucigalpa',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Thule': TimezoneData(
    tzid: 'America/Thule',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Tijuana': TimezoneData(
    tzid: 'America/Tijuana',
    standardName: 'PST',
    standardOffset: '-0800',
  ),
  'America/Toronto': TimezoneData(
    tzid: 'America/Toronto',
    standardName: 'EST',
    standardOffset: '-0500',
  ),
  'America/Tortola': TimezoneData(
    tzid: 'America/Tortola',
    standardName: 'AST',
    standardOffset: '-0400',
  ),
  'America/Vancouver': TimezoneData(
    tzid: 'America/Vancouver',
    standardName: 'PST',
    standardOffset: '-0800',
  ),
  'America/Whitehorse': TimezoneData(
    tzid: 'America/Whitehorse',
    standardName: 'MST',
    standardOffset: '-0700',
  ),
  'America/Winnipeg': TimezoneData(
    tzid: 'America/Winnipeg',
    standardName: 'CST',
    standardOffset: '-0600',
  ),
  'America/Yakutat': TimezoneData(
    tzid: 'America/Yakutat',
    standardName: 'AKST',
    standardOffset: '-0900',
  ),
  'America/Yellowknife': TimezoneData(
    tzid: 'America/Yellowknife',
    standardName: 'MST',
    standardOffset: '-0700',
  ),
  // ========== ARCTIC ==========
  'Arctic/Longyearbyen': TimezoneData(
    tzid: 'Arctic/Longyearbyen',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  // ========== ASIA ==========
  'Asia/Aden': TimezoneData(
    tzid: 'Asia/Aden',
    standardName: 'AST',
    standardOffset: '+0300',
  ),
  'Asia/Almaty': TimezoneData(
    tzid: 'Asia/Almaty',
    standardName: 'ALMT',
    standardOffset: '+0600',
  ),
  'Asia/Amman': TimezoneData(
    tzid: 'Asia/Amman',
    standardName: 'EET',
    standardOffset: '+0200',
  ),
  'Asia/Anadyr': TimezoneData(
    tzid: 'Asia/Anadyr',
    standardName: 'ANAT',
    standardOffset: '+1200',
  ),
  'Asia/Aqtau': TimezoneData(
    tzid: 'Asia/Aqtau',
    standardName: 'AQTT',
    standardOffset: '+0500',
  ),
  'Asia/Aqtobe': TimezoneData(
    tzid: 'Asia/Aqtobe',
    standardName: 'AQTT',
    standardOffset: '+0500',
  ),
  'Asia/Ashgabat': TimezoneData(
    tzid: 'Asia/Ashgabat',
    standardName: 'TMT',
    standardOffset: '+0500',
  ),
  'Asia/Atyrau': TimezoneData(
    tzid: 'Asia/Atyrau',
    standardName: 'AQTT',
    standardOffset: '+0500',
  ),
  'Asia/Baghdad': TimezoneData(
    tzid: 'Asia/Baghdad',
    standardName: 'AST',
    standardOffset: '+0300',
  ),
  'Asia/Bahrain': TimezoneData(
    tzid: 'Asia/Bahrain',
    standardName: 'AST',
    standardOffset: '+0300',
  ),
  'Asia/Baku': TimezoneData(
    tzid: 'Asia/Baku',
    standardName: 'AZT',
    standardOffset: '+0400',
  ),
  'Asia/Barnaul': TimezoneData(
    tzid: 'Asia/Barnaul',
    standardName: 'ALMT',
    standardOffset: '+0700',
  ),
  'Asia/Beirut': TimezoneData(
    tzid: 'Asia/Beirut',
    standardName: 'EET',
    standardOffset: '+0200',
  ),
  'Asia/Brunei': TimezoneData(
    tzid: 'Asia/Brunei',
    standardName: 'BNT',
    standardOffset: '+0800',
  ),
  'Asia/Chita': TimezoneData(
    tzid: 'Asia/Chita',
    standardName: 'YAKT',
    standardOffset: '+0900',
  ),
  'Asia/Choibalsan': TimezoneData(
    tzid: 'Asia/Choibalsan',
    standardName: 'ULAT',
    standardOffset: '+0800',
  ),
  'Asia/Colombo': TimezoneData(
    tzid: 'Asia/Colombo',
    standardName: 'IST',
    standardOffset: '+0530',
  ),
  'Asia/Damascus': TimezoneData(
    tzid: 'Asia/Damascus',
    standardName: 'EET',
    standardOffset: '+0200',
  ),
  'Asia/Dhaka': TimezoneData(
    tzid: 'Asia/Dhaka',
    standardName: 'BDT',
    standardOffset: '+0600',
  ),
  'Asia/Dili': TimezoneData(
    tzid: 'Asia/Dili',
    standardName: 'TLT',
    standardOffset: '+0900',
  ),
  'Asia/Dubai': TimezoneData(
    tzid: 'Asia/Dubai',
    standardName: 'GST',
    standardOffset: '+0400',
  ),
  'Asia/Dushanbe': TimezoneData(
    tzid: 'Asia/Dushanbe',
    standardName: 'TJT',
    standardOffset: '+0500',
  ),
  'Asia/Famagusta': TimezoneData(
    tzid: 'Asia/Famagusta',
    standardName: 'EET',
    standardOffset: '+0200',
  ),
  'Asia/Gaza': TimezoneData(
    tzid: 'Asia/Gaza',
    standardName: 'IST',
    standardOffset: '+0200',
  ),
  'Asia/Hebron': TimezoneData(
    tzid: 'Asia/Hebron',
    standardName: 'IST',
    standardOffset: '+0200',
  ),
  'Asia/Ho_Chi_Minh': TimezoneData(
    tzid: 'Asia/Ho_Chi_Minh',
    standardName: 'ICT',
    standardOffset: '+0700',
  ),
  'Asia/Hong_Kong': TimezoneData(
    tzid: 'Asia/Hong_Kong',
    standardName: 'HKT',
    standardOffset: '+0800',
  ),
  'Asia/Hovd': TimezoneData(
    tzid: 'Asia/Hovd',
    standardName: 'HOVT',
    standardOffset: '+0700',
  ),
  'Asia/Irkutsk': TimezoneData(
    tzid: 'Asia/Irkutsk',
    standardName: 'IRKT',
    standardOffset: '+0800',
  ),
  'Asia/Jakarta': TimezoneData(
    tzid: 'Asia/Jakarta',
    standardName: 'WIB',
    standardOffset: '+0700',
  ),
  'Asia/Jayapura': TimezoneData(
    tzid: 'Asia/Jayapura',
    standardName: 'WIT',
    standardOffset: '+0900',
  ),
  'Asia/Kabul': TimezoneData(
    tzid: 'Asia/Kabul',
    standardName: 'AFT',
    standardOffset: '+0430',
  ),
  'Asia/Kamchatka': TimezoneData(
    tzid: 'Asia/Kamchatka',
    standardName: 'PETT',
    standardOffset: '+1200',
  ),
  'Asia/Karachi': TimezoneData(
    tzid: 'Asia/Karachi',
    standardName: 'PKT',
    standardOffset: '+0500',
  ),
  'Asia/Kathmandu': TimezoneData(
    tzid: 'Asia/Kathmandu',
    standardName: 'NPT',
    standardOffset: '+0545',
  ),
  'Asia/Khandyga': TimezoneData(
    tzid: 'Asia/Khandyga',
    standardName: 'YAKT',
    standardOffset: '+0900',
  ),
  'Asia/Kolkata': TimezoneData(
    tzid: 'Asia/Kolkata',
    standardName: 'IST',
    standardOffset: '+0530',
  ),
  'Asia/Krasnoyarsk': TimezoneData(
    tzid: 'Asia/Krasnoyarsk',
    standardName: 'KRAT',
    standardOffset: '+0700',
  ),
  'Asia/Kuala_Lumpur': TimezoneData(
    tzid: 'Asia/Kuala_Lumpur',
    standardName: 'MYT',
    standardOffset: '+0800',
  ),
  'Asia/Kuching': TimezoneData(
    tzid: 'Asia/Kuching',
    standardName: 'MYT',
    standardOffset: '+0800',
  ),
  'Asia/Kuwait': TimezoneData(
    tzid: 'Asia/Kuwait',
    standardName: 'AST',
    standardOffset: '+0300',
  ),
  'Asia/Macau': TimezoneData(
    tzid: 'Asia/Macau',
    standardName: 'CST',
    standardOffset: '+0800',
  ),
  'Asia/Magadan': TimezoneData(
    tzid: 'Asia/Magadan',
    standardName: 'MAGT',
    standardOffset: '+1200',
  ),
  'Asia/Makassar': TimezoneData(
    tzid: 'Asia/Makassar',
    standardName: 'WITA',
    standardOffset: '+0800',
  ),
  'Asia/Manila': TimezoneData(
    tzid: 'Asia/Manila',
    standardName: 'PHT',
    standardOffset: '+0800',
  ),
  'Asia/Muscat': TimezoneData(
    tzid: 'Asia/Muscat',
    standardName: 'GST',
    standardOffset: '+0400',
  ),
  'Asia/Nicosia': TimezoneData(
    tzid: 'Asia/Nicosia',
    standardName: 'EET',
    standardOffset: '+0200',
  ),
  'Asia/Novokuznetsk': TimezoneData(
    tzid: 'Asia/Novokuznetsk',
    standardName: 'KRAT',
    standardOffset: '+0700',
  ),
  'Asia/Novosibirsk': TimezoneData(
    tzid: 'Asia/Novosibirsk',
    standardName: 'NOVT',
    standardOffset: '+0700',
  ),
  'Asia/Omsk': TimezoneData(
    tzid: 'Asia/Omsk',
    standardName: 'OMST',
    standardOffset: '+0600',
  ),
  'Asia/Oral': TimezoneData(
    tzid: 'Asia/Oral',
    standardName: 'ORAT',
    standardOffset: '+0500',
  ),
  'Asia/Phnom_Penh': TimezoneData(
    tzid: 'Asia/Phnom_Penh',
    standardName: 'ICT',
    standardOffset: '+0700',
  ),
  'Asia/Pontianak': TimezoneData(
    tzid: 'Asia/Pontianak',
    standardName: 'WIB',
    standardOffset: '+0700',
  ),
  'Asia/Pyongyang': TimezoneData(
    tzid: 'Asia/Pyongyang',
    standardName: 'KST',
    standardOffset: '+0900',
  ),
  'Asia/Qatar': TimezoneData(
    tzid: 'Asia/Qatar',
    standardName: 'AST',
    standardOffset: '+0300',
  ),
  'Asia/Qostanay': TimezoneData(
    tzid: 'Asia/Qostanay',
    standardName: 'ALMT',
    standardOffset: '+0600',
  ),
  'Asia/Qyzylorda': TimezoneData(
    tzid: 'Asia/Qyzylorda',
    standardName: 'QYZT',
    standardOffset: '+0500',
  ),
  'Asia/Riyadh': TimezoneData(
    tzid: 'Asia/Riyadh',
    standardName: 'AST',
    standardOffset: '+0300',
  ),
  'Asia/Sakhalin': TimezoneData(
    tzid: 'Asia/Sakhalin',
    standardName: 'SAKT',
    standardOffset: '+1100',
  ),
  'Asia/Samarkand': TimezoneData(
    tzid: 'Asia/Samarkand',
    standardName: 'UZT',
    standardOffset: '+0500',
  ),
  'Asia/Seoul': TimezoneData(
    tzid: 'Asia/Seoul',
    standardName: 'KST',
    standardOffset: '+0900',
  ),
  'Asia/Shanghai': TimezoneData(
    tzid: 'Asia/Shanghai',
    standardName: 'CST',
    standardOffset: '+0800',
  ),
  'Asia/Singapore': TimezoneData(
    tzid: 'Asia/Singapore',
    standardName: 'SGT',
    standardOffset: '+0800',
  ),
  'Asia/Taipei': TimezoneData(
    tzid: 'Asia/Taipei',
    standardName: 'CST',
    standardOffset: '+0800',
  ),
  'Asia/Tashkent': TimezoneData(
    tzid: 'Asia/Tashkent',
    standardName: 'UZT',
    standardOffset: '+0500',
  ),
  'Asia/Tbilisi': TimezoneData(
    tzid: 'Asia/Tbilisi',
    standardName: 'GET',
    standardOffset: '+0400',
  ),
  'Asia/Tehran': TimezoneData(
    tzid: 'Asia/Tehran',
    standardName: 'IRST',
    standardOffset: '+0330',
  ),
  'Asia/Thimphu': TimezoneData(
    tzid: 'Asia/Thimphu',
    standardName: 'BTT',
    standardOffset: '+0600',
  ),
  'Asia/Tokyo': TimezoneData(
    tzid: 'Asia/Tokyo',
    standardName: 'JST',
    standardOffset: '+0900',
  ),
  'Asia/Tomsk': TimezoneData(
    tzid: 'Asia/Tomsk',
    standardName: 'TOMT',
    standardOffset: '+0700',
  ),
  'Asia/Ulaanbaatar': TimezoneData(
    tzid: 'Asia/Ulaanbaatar',
    standardName: 'ULAT',
    standardOffset: '+0800',
  ),
  'Asia/Urumqi': TimezoneData(
    tzid: 'Asia/Urumqi',
    standardName: 'URUT',
    standardOffset: '+0600',
  ),
  'Asia/Ust-Nera': TimezoneData(
    tzid: 'Asia/Ust-Nera',
    standardName: 'VLAT',
    standardOffset: '+1000',
  ),
  'Asia/Vientiane': TimezoneData(
    tzid: 'Asia/Vientiane',
    standardName: 'ICT',
    standardOffset: '+0700',
  ),
  'Asia/Vladivostok': TimezoneData(
    tzid: 'Asia/Vladivostok',
    standardName: 'VLAT',
    standardOffset: '+1000',
  ),
  'Asia/Yakutsk': TimezoneData(
    tzid: 'Asia/Yakutsk',
    standardName: 'YAKT',
    standardOffset: '+0900',
  ),
  'Asia/Yangon': TimezoneData(
    tzid: 'Asia/Yangon',
    standardName: 'MMT',
    standardOffset: '+0630',
  ),
  'Asia/Yekaterinburg': TimezoneData(
    tzid: 'Asia/Yekaterinburg',
    standardName: 'YEKT',
    standardOffset: '+0500',
  ),
  'Asia/Yerevan': TimezoneData(
    tzid: 'Asia/Yerevan',
    standardName: 'AMT',
    standardOffset: '+0400',
  ),
  
  // ========== ATLANTIC ==========
  'Atlantic/Azores': TimezoneData(
    tzid: 'Atlantic/Azores',
    standardName: 'AZOT',
    standardOffset: '-0100',
    daylightName: 'AZOST',
    daylightOffset: '+0000',
  ),
  'Atlantic/Bermuda': TimezoneData(
    tzid: 'Atlantic/Bermuda',
    standardName: 'AST',
    standardOffset: '-0400',
    daylightName: 'ADT',
    daylightOffset: '-0300',
  ),
  'Atlantic/Canary': TimezoneData(
    tzid: 'Atlantic/Canary',
    standardName: 'WET',
    standardOffset: '+0000',
    daylightName: 'WEST',
    daylightOffset: '+0100',
  ),
  'Atlantic/Cape_Verde': TimezoneData(
    tzid: 'Atlantic/Cape_Verde',
    standardName: 'CVT',
    standardOffset: '-0100',
  ),
  'Atlantic/Faroe': TimezoneData(
    tzid: 'Atlantic/Faroe',
    standardName: 'WET',
    standardOffset: '+0000',
  ),
  'Atlantic/Madeira': TimezoneData(
    tzid: 'Atlantic/Madeira',
    standardName: 'WET',
    standardOffset: '+0000',
  ),
  'Atlantic/Reykjavik': TimezoneData(
    tzid: 'Atlantic/Reykjavik',
    standardName: 'GMT',
    standardOffset: '+0000',
  ),
  'Atlantic/South_Georgia': TimezoneData(
    tzid: 'Atlantic/South_Georgia',
    standardName: 'GST',
    standardOffset: '-0200',
  ),
  'Atlantic/St_Helena': TimezoneData(
    tzid: 'Atlantic/St_Helena',
    standardName: 'GMT',
    standardOffset: '+0000',
  ),
  'Atlantic/Stanley': TimezoneData(
    tzid: 'Atlantic/Stanley',
    standardName: 'FKT',
    standardOffset: '-0300',
  ),
  
  // ========== AUSTRALIA ==========
  'Australia/Adelaide': TimezoneData(
    tzid: 'Australia/Adelaide',
    standardName: 'ACST',
    standardOffset: '+0930',
    daylightName: 'ACDT',
    daylightOffset: '+1030',
  ),
  'Australia/Brisbane': TimezoneData(
    tzid: 'Australia/Brisbane',
    standardName: 'AEST',
    standardOffset: '+1000',
  ),
  'Australia/Broken_Hill': TimezoneData(
    tzid: 'Australia/Broken_Hill',
    standardName: 'ACST',
    standardOffset: '+0930',
  ),
  'Australia/Darwin': TimezoneData(
    tzid: 'Australia/Darwin',
    standardName: 'ACST',
    standardOffset: '+0930',
  ),
  'Australia/Eucla': TimezoneData(
    tzid: 'Australia/Eucla',
    standardName: 'ACWST',
    standardOffset: '+0845',
  ),
  'Australia/Hobart': TimezoneData(
    tzid: 'Australia/Hobart',
    standardName: 'AEST',
    standardOffset: '+1000',
    daylightName: 'AEDT',
    daylightOffset: '+1100',
  ),
  'Australia/Lord_Howe': TimezoneData(
    tzid: 'Australia/Lord_Howe',
    standardName: 'LHST',
    standardOffset: '+1030',
  ),
  'Australia/Melbourne': TimezoneData(
    tzid: 'Australia/Melbourne',
    standardName: 'AEST',
    standardOffset: '+1000',
    daylightName: 'AEDT',
    daylightOffset: '+1100',
  ),
  'Australia/Perth': TimezoneData(
    tzid: 'Australia/Perth',
    standardName: 'AWST',
    standardOffset: '+0800',
  ),
  'Australia/Sydney': TimezoneData(
    tzid: 'Australia/Sydney',
    standardName: 'AEST',
    standardOffset: '+1000',
    daylightName: 'AEDT',
    daylightOffset: '+1100',
  ),
  
  // ========== EUROPE ==========
  'Europe/Amsterdam': TimezoneData(
    tzid: 'Europe/Amsterdam',
    standardName: 'CET',
    standardOffset: '+0100',
    daylightName: 'CEST',
    daylightOffset: '+0200',
  ),
  'Europe/Andorra': TimezoneData(
    tzid: 'Europe/Andorra',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Europe/Astrakhan': TimezoneData(
    tzid: 'Europe/Astrakhan',
    standardName: 'ASUT',
    standardOffset: '+0400',
  ),
  'Europe/Athens': TimezoneData(
    tzid: 'Europe/Athens',
    standardName: 'EET',
    standardOffset: '+0200',
    daylightName: 'EEST',
    daylightOffset: '+0300',
  ),
  'Europe/Berlin': TimezoneData(
    tzid: 'Europe/Berlin',
    standardName: 'CET',
    standardOffset: '+0100',
    daylightName: 'CEST',
    daylightOffset: '+0200',
  ),
  'Europe/Bratislava': TimezoneData(
    tzid: 'Europe/Bratislava',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Europe/Brussels': TimezoneData(
    tzid: 'Europe/Brussels',
    standardName: 'CET',
    standardOffset: '+0100',
    daylightName: 'CEST',
    daylightOffset: '+0200',
  ),
  'Europe/Bucharest': TimezoneData(
    tzid: 'Europe/Bucharest',
    standardName: 'EET',
    standardOffset: '+0200',
  ),
  'Europe/Budapest': TimezoneData(
    tzid: 'Europe/Budapest',
    standardName: 'CET',
    standardOffset: '+0100',
    daylightName: 'CEST',
    daylightOffset: '+0200',
  ),
  'Europe/Busingen': TimezoneData(
    tzid: 'Europe/Busingen',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Europe/Chisinau': TimezoneData(
    tzid: 'Europe/Chisinau',
    standardName: 'EET',
    standardOffset: '+0200',
  ),
  'Europe/Copenhagen': TimezoneData(
    tzid: 'Europe/Copenhagen',
    standardName: 'CET',
    standardOffset: '+0100',
    daylightName: 'CEST',
    daylightOffset: '+0200',
  ),
  'Europe/Dublin': TimezoneData(
    tzid: 'Europe/Dublin',
    standardName: 'GMT',
    standardOffset: '+0000',
    daylightName: 'IST',
    daylightOffset: '+0100',
  ),
  'Europe/Gibraltar': TimezoneData(
    tzid: 'Europe/Gibraltar',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Europe/Guernsey': TimezoneData(
    tzid: 'Europe/Guernsey',
    standardName: 'GMT',
    standardOffset: '+0000',
  ),
  'Europe/Helsinki': TimezoneData(
    tzid: 'Europe/Helsinki',
    standardName: 'EET',
    standardOffset: '+0200',
    daylightName: 'EEST',
    daylightOffset: '+0300',
  ),
  'Europe/Isle_of_Man': TimezoneData(
    tzid: 'Europe/Isle_of_Man',
    standardName: 'GMT',
    standardOffset: '+0000',
  ),
  'Europe/Istanbul': TimezoneData(
    tzid: 'Europe/Istanbul',
    standardName: 'TRT',
    standardOffset: '+0300',
  ),
  'Europe/Jersey': TimezoneData(
    tzid: 'Europe/Jersey',
    standardName: 'GMT',
    standardOffset: '+0000',
  ),
  'Europe/Kaliningrad': TimezoneData(
    tzid: 'Europe/Kaliningrad',
    standardName: 'EET',
    standardOffset: '+0200',
  ),
  'Europe/Kirov': TimezoneData(
    tzid: 'Europe/Kirov',
    standardName: 'YEKT',
    standardOffset: '+0500',
  ),
  'Europe/Kyiv': TimezoneData(
    tzid: 'Europe/Kyiv',
    standardName: 'EET',
    standardOffset: '+0200',
    daylightName: 'EEST',
    daylightOffset: '+0300',
  ),
  'Europe/Lisbon': TimezoneData(
    tzid: 'Europe/Lisbon',
    standardName: 'WET',
    standardOffset: '+0000',
    daylightName: 'WEST',
    daylightOffset: '+0100',
  ),
  'Europe/Ljubljana': TimezoneData(
    tzid: 'Europe/Ljubljana',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Europe/London': TimezoneData(
    tzid: 'Europe/London',
    standardName: 'GMT',
    standardOffset: '+0000',
    daylightName: 'BST',
    daylightOffset: '+0100',
  ),
  'Europe/Luxembourg': TimezoneData(
    tzid: 'Europe/Luxembourg',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Europe/Madrid': TimezoneData(
    tzid: 'Europe/Madrid',
    standardName: 'CET',
    standardOffset: '+0100',
    daylightName: 'CEST',
    daylightOffset: '+0200',
  ),
  'Europe/Malta': TimezoneData(
    tzid: 'Europe/Malta',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Europe/Mariehamn': TimezoneData(
    tzid: 'Europe/Mariehamn',
    standardName: 'EET',
    standardOffset: '+0200',
  ),
  'Europe/Minsk': TimezoneData(
    tzid: 'Europe/Minsk',
    standardName: 'MSK',
    standardOffset: '+0300',
  ),
  'Europe/Monaco': TimezoneData(
    tzid: 'Europe/Monaco',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Europe/Moscow': TimezoneData(
    tzid: 'Europe/Moscow',
    standardName: 'MSK',
    standardOffset: '+0300',
  ),
  'Europe/Oslo': TimezoneData(
    tzid: 'Europe/Oslo',
    standardName: 'CET',
    standardOffset: '+0100',
    daylightName: 'CEST',
    daylightOffset: '+0200',
  ),
  'Europe/Paris': TimezoneData(
    tzid: 'Europe/Paris',
    standardName: 'CET',
    standardOffset: '+0100',
    daylightName: 'CEST',
    daylightOffset: '+0200',
  ),
  'Europe/Podgorica': TimezoneData(
    tzid: 'Europe/Podgorica',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Europe/Prague': TimezoneData(
    tzid: 'Europe/Prague',
    standardName: 'CET',
    standardOffset: '+0100',
    daylightName: 'CEST',
    daylightOffset: '+0200',
  ),
  'Europe/Riga': TimezoneData(
    tzid: 'Europe/Riga',
    standardName: 'EET',
    standardOffset: '+0200',
  ),
  'Europe/Rome': TimezoneData(
    tzid: 'Europe/Rome',
    standardName: 'CET',
    standardOffset: '+0100',
    daylightName: 'CEST',
    daylightOffset: '+0200',
  ),
  'Europe/Samara': TimezoneData(
    tzid: 'Europe/Samara',
    standardName: 'SAMT',
    standardOffset: '+0400',
  ),
  'Europe/San_Marino': TimezoneData(
    tzid: 'Europe/San_Marino',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Europe/Sarajevo': TimezoneData(
    tzid: 'Europe/Sarajevo',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Europe/Saratov': TimezoneData(
    tzid: 'Europe/Saratov',
    standardName: 'SAST',
    standardOffset: '+0400',
  ),
  'Europe/Skopje': TimezoneData(
    tzid: 'Europe/Skopje',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Europe/Sofia': TimezoneData(
    tzid: 'Europe/Sofia',
    standardName: 'EET',
    standardOffset: '+0200',
  ),
  'Europe/Stockholm': TimezoneData(
    tzid: 'Europe/Stockholm',
    standardName: 'CET',
    standardOffset: '+0100',
    daylightName: 'CEST',
    daylightOffset: '+0200',
  ),
  'Europe/Tallinn': TimezoneData(
    tzid: 'Europe/Tallinn',
    standardName: 'EET',
    standardOffset: '+0200',
  ),
  'Europe/Tirane': TimezoneData(
    tzid: 'Europe/Tirane',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Europe/Ulyanovsk': TimezoneData(
    tzid: 'Europe/Ulyanovsk',
    standardName: 'ULAT',
    standardOffset: '+0400',
  ),
  'Europe/Vaduz': TimezoneData(
    tzid: 'Europe/Vaduz',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Europe/Vatican': TimezoneData(
    tzid: 'Europe/Vatican',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Europe/Vienna': TimezoneData(
    tzid: 'Europe/Vienna',
    standardName: 'CET',
    standardOffset: '+0100',
    daylightName: 'CEST',
    daylightOffset: '+0200',
  ),
  'Europe/Vilnius': TimezoneData(
    tzid: 'Europe/Vilnius',
    standardName: 'EET',
    standardOffset: '+0200',
  ),
  'Europe/Volgograd': TimezoneData(
    tzid: 'Europe/Volgograd',
    standardName: 'VOLT',
    standardOffset: '+0300',
  ),
  'Europe/Warsaw': TimezoneData(
    tzid: 'Europe/Warsaw',
    standardName: 'CET',
    standardOffset: '+0100',
    daylightName: 'CEST',
    daylightOffset: '+0200',
  ),
  'Europe/Zagreb': TimezoneData(
    tzid: 'Europe/Zagreb',
    standardName: 'CET',
    standardOffset: '+0100',
  ),
  'Europe/Zurich': TimezoneData(
    tzid: 'Europe/Zurich',
    standardName: 'CET',
    standardOffset: '+0100',
    daylightName: 'CEST',
    daylightOffset: '+0200',
  ),

  // ========== INDIAN ==========
  'Indian/Antananarivo': TimezoneData(
    tzid: 'Indian/Antananarivo',
    standardName: 'EAT',
    standardOffset: '+0300',
  ),
  'Indian/Chagos': TimezoneData(
    tzid: 'Indian/Chagos',
    standardName: 'IOT',
    standardOffset: '+0600',
  ),
  'Indian/Christmas': TimezoneData(
    tzid: 'Indian/Christmas',
    standardName: 'CXT',
    standardOffset: '+0700',
  ),
  'Indian/Cocos': TimezoneData(
    tzid: 'Indian/Cocos',
    standardName: 'CCT',
    standardOffset: '+0630',
  ),
  'Indian/Comoro': TimezoneData(
    tzid: 'Indian/Comoro',
    standardName: 'EAT',
    standardOffset: '+0300',
  ),
  'Indian/Kerguelen': TimezoneData(
    tzid: 'Indian/Kerguelen',
    standardName: 'TFT',
    standardOffset: '+0500',
  ),
  'Indian/Mahe': TimezoneData(
    tzid: 'Indian/Mahe',
    standardName: 'SCT',
    standardOffset: '+0400',
  ),
  'Indian/Maldives': TimezoneData(
    tzid: 'Indian/Maldives',
    standardName: 'MVT',
    standardOffset: '+0500',
  ),
  'Indian/Mauritius': TimezoneData(
    tzid: 'Indian/Mauritius',
    standardName: 'MUT',
    standardOffset: '+0400',
  ),
  'Indian/Mayotte': TimezoneData(
    tzid: 'Indian/Mayotte',
    standardName: 'EAT',
    standardOffset: '+0300',
  ),
  'Indian/Reunion': TimezoneData(
    tzid: 'Indian/Reunion',
    standardName: 'RET',
    standardOffset: '+0400',
  ),

  // ========== PACIFIC ==========
  'Pacific/Apia': TimezoneData(
    tzid: 'Pacific/Apia',
    standardName: 'WSST',
    standardOffset: '+1300',
  ),
  'Pacific/Auckland': TimezoneData(
    tzid: 'Pacific/Auckland',
    standardName: 'NZST',
    standardOffset: '+1200',
    daylightName: 'NZDT',
    daylightOffset: '+1300',
  ),
  'Pacific/Bougainville': TimezoneData(
    tzid: 'Pacific/Bougainville',
    standardName: 'BST',
    standardOffset: '+1100',
  ),
  'Pacific/Chatham': TimezoneData(
    tzid: 'Pacific/Chatham',
    standardName: 'CHAST',
    standardOffset: '+1245',
    daylightName: 'CHADT',
    daylightOffset: '+1345',
  ),
  'Pacific/Chuuk': TimezoneData(
    tzid: 'Pacific/Chuuk',
    standardName: 'CHUT',
    standardOffset: '+1000',
  ),
  'Pacific/Easter': TimezoneData(
    tzid: 'Pacific/Easter',
    standardName: 'EAST',
    standardOffset: '-0600',
    daylightName: 'EASST',
    daylightOffset: '-0500',
  ),
  'Pacific/Efate': TimezoneData(
    tzid: 'Pacific/Efate',
    standardName: 'VUT',
    standardOffset: '+1100',
  ),
  'Pacific/Fakaofo': TimezoneData(
    tzid: 'Pacific/Fakaofo',
    standardName: 'TKT',
    standardOffset: '+1300',
  ),
  'Pacific/Fiji': TimezoneData(
    tzid: 'Pacific/Fiji',
    standardName: 'FJT',
    standardOffset: '+1200',
    daylightName: 'FJST',
    daylightOffset: '+1300',
  ),
  'Pacific/Funafuti': TimezoneData(
    tzid: 'Pacific/Funafuti',
    standardName: 'TVT',
    standardOffset: '+1200',
  ),
  'Pacific/Galapagos': TimezoneData(
    tzid: 'Pacific/Galapagos',
    standardName: 'GALT',
    standardOffset: '-0600',
  ),
  'Pacific/Gambier': TimezoneData(
    tzid: 'Pacific/Gambier',
    standardName: 'GAMT',
    standardOffset: '-0900',
  ),
  'Pacific/Guadalcanal': TimezoneData(
    tzid: 'Pacific/Guadalcanal',
    standardName: 'SBT',
    standardOffset: '+1100',
  ),
  'Pacific/Guam': TimezoneData(
    tzid: 'Pacific/Guam',
    standardName: 'ChST',
    standardOffset: '+1000',
  ),
  'Pacific/Honolulu': TimezoneData(
    tzid: 'Pacific/Honolulu',
    standardName: 'HST',
    standardOffset: '-1000',
  ),
  'Pacific/Kiritimati': TimezoneData(
    tzid: 'Pacific/Kiritimati',
    standardName: 'LINT',
    standardOffset: '+1400',
  ),
  'Pacific/Kosrae': TimezoneData(
    tzid: 'Pacific/Kosrae',
    standardName: 'KOST',
    standardOffset: '+1100',
  ),
  'Pacific/Kwajalein': TimezoneData(
    tzid: 'Pacific/Kwajalein',
    standardName: 'MHT',
    standardOffset: '+1200',
  ),
  'Pacific/Majuro': TimezoneData(
    tzid: 'Pacific/Majuro',
    standardName: 'MHT',
    standardOffset: '+1200',
  ),
  'Pacific/Marquesas': TimezoneData(
    tzid: 'Pacific/Marquesas',
    standardName: 'MART',
    standardOffset: '-0930',
  ),
  'Pacific/Midway': TimezoneData(
    tzid: 'Pacific/Midway',
    standardName: 'SST',
    standardOffset: '-1100',
  ),
  'Pacific/Nauru': TimezoneData(
    tzid: 'Pacific/Nauru',
    standardName: 'NRT',
    standardOffset: '+1200',
  ),
  'Pacific/Niue': TimezoneData(
    tzid: 'Pacific/Niue',
    standardName: 'NUT',
    standardOffset: '-1100',
  ),
  'Pacific/Norfolk': TimezoneData(
    tzid: 'Pacific/Norfolk',
    standardName: 'NFT',
    standardOffset: '+1130',
  ),
  'Pacific/Noumea': TimezoneData(
    tzid: 'Pacific/Noumea',
    standardName: 'NCT',
    standardOffset: '+1100',
  ),
  'Pacific/Pago_Pago': TimezoneData(
    tzid: 'Pacific/Pago_Pago',
    standardName: 'SST',
    standardOffset: '-1100',
  ),
  'Pacific/Palau': TimezoneData(
    tzid: 'Pacific/Palau',
    standardName: 'PWT',
    standardOffset: '+0900',
  ),
  'Pacific/Pitcairn': TimezoneData(
    tzid: 'Pacific/Pitcairn',
    standardName: 'PST',
    standardOffset: '-0800',
  ),
  'Pacific/Pohnpei': TimezoneData(
    tzid: 'Pacific/Pohnpei',
    standardName: 'PONT',
    standardOffset: '+1100',
  ),
  'Pacific/Rarotonga': TimezoneData(
    tzid: 'Pacific/Rarotonga',
    standardName: 'CKT',
    standardOffset: '-1000',
  ),
  'Pacific/Saipan': TimezoneData(
    tzid: 'Pacific/Saipan',
    standardName: 'ChST',
    standardOffset: '+1000',
  ),
  'Pacific/Tahiti': TimezoneData(
    tzid: 'Pacific/Tahiti',
    standardName: 'TAHT',
    standardOffset: '-1000',
  ),
  'Pacific/Tarawa': TimezoneData(
    tzid: 'Pacific/Tarawa',
    standardName: 'GILT',
    standardOffset: '+1200',
  ),
  'Pacific/Tongatapu': TimezoneData(
    tzid: 'Pacific/Tongatapu',
    standardName: 'TOT',
    standardOffset: '+1300',
  ),
  'Pacific/Wallis': TimezoneData(
    tzid: 'Pacific/Wallis',
    standardName: 'WFT',
    standardOffset: '+1200',
  ),
};