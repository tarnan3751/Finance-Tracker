/// The shared merchant pools and payees. Raw descriptions are strings Plaid recognizes and
/// normalizes (`PLAN.md` §7.1 rule 4); categories are Plaid v2 detailed codes, checked
/// against the taxonomy by the ledger and by `test/coverage_test.dart`. Amounts are
/// minor units of US dollars. Employers, landlords and servicers are fictional.
library;

import 'package:persona_engine/src/model/persona.dart';

// Groceries ---------------------------------------------------------------------------

const Merchant traderJoes = Merchant(
  ["TRADER JOE'S #552", "TRADER JOE'S #127"],
  "Trader Joe's",
  'FOOD_AND_DRINK_GROCERIES',
  1200,
  9500,
  weight: 3,
);
const Merchant wholeFoods = Merchant(
  ['WHOLEFDS MKT #10234', 'WHOLEFDS MKT #10571'],
  'Whole Foods',
  'FOOD_AND_DRINK_GROCERIES',
  1800,
  14000,
  weight: 2,
);
const Merchant safeway = Merchant(
  ['SAFEWAY #1711', 'SAFEWAY #0985'],
  'Safeway',
  'FOOD_AND_DRINK_GROCERIES',
  900,
  12000,
  weight: 2,
);
const Merchant kroger = Merchant(
  ['KROGER #0441'],
  'Kroger',
  'FOOD_AND_DRINK_GROCERIES',
  2500,
  18000,
  weight: 3,
);
const Merchant aldi = Merchant(
  ['ALDI 72031'],
  'Aldi',
  'FOOD_AND_DRINK_GROCERIES',
  800,
  5500,
  weight: 2,
);
const Merchant costco = Merchant(
  ['COSTCO WHSE #0123'],
  'Costco',
  'GENERAL_MERCHANDISE_SUPERSTORES',
  6000,
  26000,
);

// Food and drink ----------------------------------------------------------------------

const Merchant starbucks = Merchant(
  ['STARBUCKS STORE 08812', 'STARBUCKS STORE 11240'],
  'Starbucks',
  'FOOD_AND_DRINK_COFFEE',
  395,
  925,
  weight: 3,
);
const Merchant blueBottle = Merchant(
  ['SQ *BLUE BOTTLE COFFEE'],
  'Blue Bottle Coffee',
  'FOOD_AND_DRINK_COFFEE',
  450,
  1100,
);
const Merchant chipotle = Merchant(
  ['CHIPOTLE 1187'],
  'Chipotle',
  'FOOD_AND_DRINK_FAST_FOOD',
  1050,
  2400,
  weight: 2,
);
const Merchant mcdonalds = Merchant(
  ["MCDONALD'S F3398"],
  "McDonald's",
  'FOOD_AND_DRINK_FAST_FOOD',
  650,
  2800,
  weight: 2,
);
const Merchant chickFilA = Merchant(
  ['CHICK-FIL-A #02145'],
  'Chick-fil-A',
  'FOOD_AND_DRINK_FAST_FOOD',
  900,
  3500,
);
const Merchant sweetgreen = Merchant(
  ['SWEETGREEN MISSION'],
  'Sweetgreen',
  'FOOD_AND_DRINK_RESTAURANT',
  1300,
  2600,
);
const Merchant olive = Merchant(
  ['OLIVE GARDEN 0021'],
  'Olive Garden',
  'FOOD_AND_DRINK_RESTAURANT',
  3500,
  11000,
);
const Merchant cheesecake = Merchant(
  ['THE CHEESECAKE FACTORY'],
  'The Cheesecake Factory',
  'FOOD_AND_DRINK_RESTAURANT',
  4500,
  16000,
);
const Merchant doordashOrder = Merchant(
  ['DOORDASH*THAI BASIL'],
  'DoorDash',
  'FOOD_AND_DRINK_RESTAURANT',
  1800,
  5200,
);
const Merchant tavern = Merchant(
  ['TST* THE OLD TAVERN'],
  'The Old Tavern',
  'FOOD_AND_DRINK_BEER_WINE_AND_LIQUOR',
  1400,
  6500,
);
const Merchant bevmo = Merchant(
  ['BEVMO #0144'],
  'BevMo!',
  'FOOD_AND_DRINK_BEER_WINE_AND_LIQUOR',
  1500,
  6000,
);

// Transportation ----------------------------------------------------------------------

const Merchant shell = Merchant(
  ['SHELL OIL 57444212', 'SHELL OIL 57441108'],
  'Shell',
  'TRANSPORTATION_GAS',
  2800,
  7200,
  weight: 2,
);
const Merchant chevron = Merchant(
  ['CHEVRON 0091633'],
  'Chevron',
  'TRANSPORTATION_GAS',
  3000,
  7500,
);
const Merchant uberTrip = Merchant(
  ['UBER *TRIP', 'UBER *TRIP HELP.UBER.COM'],
  'Uber',
  'TRANSPORTATION_TAXIS_AND_RIDE_SHARES',
  900,
  3800,
  weight: 2,
);
const Merchant lyft = Merchant(
  ['LYFT *RIDE SUN 2PM', 'LYFT *RIDE FRI 11PM'],
  'Lyft',
  'TRANSPORTATION_TAXIS_AND_RIDE_SHARES',
  850,
  3400,
);
const Merchant clipper = Merchant(
  ['CLIPPER TRANSIT FARE'],
  'Clipper',
  'TRANSPORTATION_PUBLIC_TRANSIT',
  250,
  700,
);
const Merchant parking = Merchant(
  ['SP+ PARKING 4412'],
  'SP+ Parking',
  'TRANSPORTATION_PARKING',
  600,
  2400,
);

// General merchandise -----------------------------------------------------------------

const Merchant amazon = Merchant(
  ['AMAZON.COM*2K4LM8', 'AMZN Mktp US*7Y2QF1', 'AMAZON.COM*9H31P0'],
  'Amazon',
  'GENERAL_MERCHANDISE_ONLINE_MARKETPLACES',
  1200,
  12000,
  weight: 3,
);
const Merchant target = Merchant(
  ['TARGET T-1234', 'TARGET T-0871'],
  'Target',
  'GENERAL_MERCHANDISE_SUPERSTORES',
  1500,
  15000,
  weight: 2,
);
const Merchant oldNavy = Merchant(
  ['OLD NAVY ON-LINE'],
  'Old Navy',
  'GENERAL_MERCHANDISE_CLOTHING_AND_ACCESSORIES',
  2000,
  9000,
);
const Merchant gap = Merchant(
  ['GAP KIDS #2231'],
  'Gap',
  'GENERAL_MERCHANDISE_CLOTHING_AND_ACCESSORIES',
  2500,
  11000,
);
const Merchant petco = Merchant(
  ['PETCO 1234'],
  'Petco',
  'GENERAL_MERCHANDISE_PET_SUPPLIES',
  1500,
  8000,
);
const Merchant cvs = Merchant(
  ['CVS/PHARMACY #04321'],
  'CVS',
  'MEDICAL_PHARMACIES_AND_SUPPLEMENTS',
  600,
  4500,
  weight: 2,
);
const Merchant walgreens = Merchant(
  ['WALGREENS #7714'],
  'Walgreens',
  'MEDICAL_PHARMACIES_AND_SUPPLEMENTS',
  500,
  3800,
);
const Merchant bookstore = Merchant(
  ['STATE UNIV BOOKSTORE'],
  'State University Bookstore',
  'GENERAL_MERCHANDISE_BOOKSTORES_AND_NEWSSTANDS',
  1800,
  14000,
);
const Merchant staples = Merchant(
  ['STAPLES 00114'],
  'Staples',
  'GENERAL_MERCHANDISE_OFFICE_SUPPLIES',
  1500,
  18000,
);
const Merchant seven11 = Merchant(
  ['7-ELEVEN 33912'],
  '7-Eleven',
  'GENERAL_MERCHANDISE_CONVENIENCE_STORES',
  300,
  1800,
);

// Home, services, medical, entertainment ----------------------------------------------

const Merchant homeDepot = Merchant(
  ['THE HOME DEPOT #0612'],
  'The Home Depot',
  'HOME_IMPROVEMENT_HARDWARE',
  1800,
  26000,
  weight: 2,
);
const Merchant lowes = Merchant(
  ["LOWE'S #1843"],
  "Lowe's",
  'HOME_IMPROVEMENT_HARDWARE',
  2000,
  21000,
);
const Merchant ikea = Merchant(
  ['IKEA EAST PALO ALTO'],
  'IKEA',
  'HOME_IMPROVEMENT_FURNITURE',
  3000,
  30000,
);
const Merchant kaiser = Merchant(
  ['KAISER PERMANENTE COPAY'],
  'Kaiser Permanente',
  'MEDICAL_PRIMARY_CARE',
  2500,
  6000,
);
const Merchant dental = Merchant(
  ['BRIGHT SMILES DENTAL'],
  'Bright Smiles Dental',
  'MEDICAL_DENTAL_CARE',
  4500,
  22000,
);
const Merchant greatClips = Merchant(
  ['GREAT CLIPS #4471'],
  'Great Clips',
  'PERSONAL_CARE_HAIR_AND_BEAUTY',
  1800,
  4000,
);
const Merchant amc = Merchant(
  ['AMC 9640 ONLINE'],
  'AMC Theatres',
  'ENTERTAINMENT_TV_AND_MOVIES',
  1200,
  6000,
);
const Merchant chuckECheese = Merchant(
  ['CHUCK E. CHEESE 0388'],
  'Chuck E. Cheese',
  'ENTERTAINMENT_SPORTING_EVENTS_AMUSEMENT_PARKS_AND_MUSEUMS',
  2500,
  8500,
);
const Merchant steam = Merchant(
  ['STEAMGAMES.COM 4259522985'],
  'Steam',
  'ENTERTAINMENT_VIDEO_GAMES',
  500,
  6000,
);
const Merchant fedex = Merchant(
  ['FEDEX 78234512', 'FEDEX OFFIC10512'],
  'FedEx',
  'GENERAL_SERVICES_POSTAGE_AND_SHIPPING',
  1200,
  9000,
);
const Merchant usps = Merchant(
  ['USPS PO 0571230145'],
  'USPS',
  'GENERAL_SERVICES_POSTAGE_AND_SHIPPING',
  600,
  4000,
);
const Merchant redCross = Merchant(
  ['AMERICAN RED CROSS'],
  'American Red Cross',
  'GOVERNMENT_AND_NON_PROFIT_DONATIONS',
  2500,
  10000,
);
const Merchant miscPos = Merchant(
  ['POS PURCHASE 4417', 'POS DEBIT 0932'],
  null,
  'OTHER_OTHER',
  500,
  4500,
);
const Merchant atmFee = Merchant(
  ['ATM FEE'],
  null,
  'BANK_FEES_ATM_FEES',
  300,
  350,
);
const Merchant atmWithdrawal = Merchant(
  ['ATM WITHDRAWAL 0412 MAIN ST'],
  null,
  'TRANSFER_OUT_WITHDRAWAL',
  4000,
  10000,
);

// Travel ------------------------------------------------------------------------------

const Merchant delta = Merchant(
  ['DELTA AIR LINES 0062'],
  'Delta',
  'TRAVEL_FLIGHTS',
  18000,
  62000,
);
const Merchant united = Merchant(
  ['UNITED 0167'],
  'United Airlines',
  'TRAVEL_FLIGHTS',
  20000,
  70000,
);
const Merchant airbnb = Merchant(
  ['AIRBNB * HMQT5K2'],
  'Airbnb',
  'TRAVEL_LODGING',
  15000,
  65000,
);
const Merchant marriott = Merchant(
  ['MARRIOTT SAN DIEGO'],
  'Marriott',
  'TRAVEL_LODGING',
  16000,
  48000,
);
const Merchant hertz = Merchant(
  ['HERTZ RENT-A-CAR'],
  'Hertz',
  'TRAVEL_RENTAL_CARS',
  9000,
  38000,
);

// Anomaly pool: one-off merchants -----------------------------------------------------

/// Merchants a household meets once: a big purchase, an emergency, a trip. None may be a
/// merchant any persona uses regularly; the generator checks it.
const List<Merchant> oneOffMerchants = [
  Merchant(
    ['BEST BUY 00123'],
    'Best Buy',
    'GENERAL_MERCHANDISE_ELECTRONICS',
    45000,
    160000,
  ),
  Merchant(
    ['CITY MEDICAL CENTER'],
    'City Medical Center',
    'MEDICAL_OTHER_MEDICAL',
    30000,
    120000,
  ),
  Merchant(
    ['SOUTHWEST AIR 5262'],
    'Southwest Airlines',
    'TRAVEL_FLIGHTS',
    25000,
    90000,
  ),
  Merchant(
    ['MIDAS AUTO SERVICE #417'],
    'Midas',
    'GENERAL_SERVICES_AUTOMOTIVE',
    35000,
    140000,
  ),
  Merchant(
    ['GUITAR CENTER #217'],
    'Guitar Center',
    'GENERAL_MERCHANDISE_OTHER_GENERAL_MERCHANDISE',
    40000,
    150000,
  ),
  Merchant(
    ['POTTERY BARN #0391'],
    'Pottery Barn',
    'HOME_IMPROVEMENT_FURNITURE',
    50000,
    180000,
  ),
  Merchant(
    ['VCA ANIMAL HOSPITAL'],
    'VCA Animal Hospitals',
    'MEDICAL_VETERINARY_SERVICES',
    30000,
    110000,
  ),
  Merchant(
    ['LENSCRAFTERS #0688'],
    'LensCrafters',
    'MEDICAL_EYE_CARE',
    25000,
    70000,
  ),
];

// Subscriptions -----------------------------------------------------------------------

const Payee netflix = Payee(
  'NETFLIX.COM',
  'Netflix',
  'ENTERTAINMENT_TV_AND_MOVIES',
);
const Payee spotify = Payee(
  'Spotify USA',
  'Spotify',
  'ENTERTAINMENT_MUSIC_AND_AUDIO',
);
const Payee hulu = Payee(
  'HULU 877-8244858',
  'Hulu',
  'ENTERTAINMENT_TV_AND_MOVIES',
);
const Payee disneyPlus = Payee(
  'DISNEY PLUS',
  'Disney+',
  'ENTERTAINMENT_TV_AND_MOVIES',
);
const Payee appleIcloud = Payee(
  'APPLE.COM/BILL',
  'Apple',
  'GENERAL_SERVICES_OTHER_GENERAL_SERVICES',
);
const Payee amazonPrime = Payee(
  'Amazon Prime*2K4LM8',
  'Amazon Prime',
  'GENERAL_MERCHANDISE_ONLINE_MARKETPLACES',
);
const Payee planetFitness = Payee(
  'PLANET FITNESS',
  'Planet Fitness',
  'PERSONAL_CARE_GYMS_AND_FITNESS_CENTERS',
);
const Payee peloton = Payee(
  'PELOTON* MEMBERSHIP',
  'Peloton',
  'PERSONAL_CARE_GYMS_AND_FITNESS_CENTERS',
);
const Payee adobe = Payee(
  'ADOBE *CREATIVE CLD',
  'Adobe',
  'GENERAL_SERVICES_OTHER_GENERAL_SERVICES',
);
const Payee googleWorkspace = Payee(
  'GOOGLE *GSUITE_STUDIO',
  'Google Workspace',
  'GENERAL_SERVICES_OTHER_GENERAL_SERVICES',
);
const Payee slack = Payee(
  'SLACK T02B4K7',
  'Slack',
  'GENERAL_SERVICES_OTHER_GENERAL_SERVICES',
);

// Utilities and services --------------------------------------------------------------

const Payee pge = Payee(
  'PGANDE WEB ONLINE',
  'PG&E',
  'RENT_AND_UTILITIES_GAS_AND_ELECTRICITY',
);
const Payee comcast = Payee(
  'COMCAST XFINITY',
  'Xfinity',
  'RENT_AND_UTILITIES_INTERNET_AND_CABLE',
);
const Payee tMobile = Payee(
  'T-MOBILE AUTOPAY',
  'T-Mobile',
  'RENT_AND_UTILITIES_TELEPHONE',
);
const Payee verizon = Payee(
  'VERIZON WIRELESS PAYMENTS',
  'Verizon',
  'RENT_AND_UTILITIES_TELEPHONE',
);
const Payee mintMobile = Payee(
  'MINT MOBILE',
  'Mint Mobile',
  'RENT_AND_UTILITIES_TELEPHONE',
);
const Payee cityWater = Payee(
  'CITY OF OAKDALE WATER',
  'City of Oakdale',
  'RENT_AND_UTILITIES_WATER',
);
const Payee wasteManagement = Payee(
  'WASTE MANAGEMENT',
  'Waste Management',
  'RENT_AND_UTILITIES_SEWAGE_AND_WASTE_MANAGEMENT',
);
const Payee lemonade = Payee(
  'LEMONADE INSURANCE',
  'Lemonade',
  'GENERAL_SERVICES_INSURANCE',
);
const Payee stateFarm = Payee(
  'STATE FARM INSURANCE',
  'State Farm',
  'GENERAL_SERVICES_INSURANCE',
);
const Payee geico = Payee('GEICO AUTO', 'GEICO', 'GENERAL_SERVICES_INSURANCE');
