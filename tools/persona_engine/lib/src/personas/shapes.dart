/// Weekly and seasonal shapes: per-mille weights, 1000 meaning an average day or month.
/// Weekly lists start on Monday, seasonal lists on January.
library;

/// Weekends heavier: most discretionary spending.
const List<int> weekendHeavy = [850, 850, 900, 950, 1150, 1300, 1000];

/// Weekdays only, nearly: commuting, coffee near work, business purchases.
const List<int> weekdays = [1200, 1200, 1200, 1200, 1100, 600, 500];

/// Saturday and Sunday outings.
const List<int> weekendOutings = [400, 400, 500, 600, 1100, 2300, 1700];

/// Every day alike.
const List<int> flatWeek = [1000, 1000, 1000, 1000, 1000, 1000, 1000];

/// Every month alike.
const List<int> flatYear = [
  1000,
  1000,
  1000,
  1000,
  1000,
  1000,
  1000,
  1000,
  1000,
  1000,
  1000,
  1000,
];

/// The holiday spike: November rising, December highest.
const List<int> holidayRetail = [
  900,
  850,
  950,
  950,
  1000,
  1000,
  1000,
  1050,
  950,
  1000,
  1250,
  1600,
];

/// Groceries: a little more for the November and December holidays.
const List<int> holidayGroceries = [
  1000,
  950,
  1000,
  1000,
  1000,
  1000,
  1000,
  1000,
  1000,
  1000,
  1150,
  1200,
];

/// Summer travel, and a smaller year-end trip.
const List<int> summerTravel = [
  400,
  400,
  700,
  700,
  900,
  2000,
  2200,
  1800,
  700,
  600,
  700,
  1500,
];

/// Dining out: a little more in summer and December.
const List<int> summerDining = [
  950,
  950,
  1000,
  1000,
  1050,
  1100,
  1100,
  1100,
  1000,
  1000,
  1000,
  1150,
];

/// Gas and electricity: heating in winter, cooling in summer.
const List<int> heatingAndCooling = [
  1500,
  1400,
  1150,
  900,
  800,
  1000,
  1300,
  1350,
  1000,
  850,
  1100,
  1450,
];

/// The academic year: books and supplies at the start of each semester.
const List<int> semesterStarts = [
  2400,
  1200,
  600,
  500,
  400,
  300,
  300,
  2600,
  1500,
  600,
  500,
  600,
];
