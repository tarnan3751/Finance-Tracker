/// The student: a graduate student with an undergraduate loan in repayment, a graduate
/// loan disbursed each semester (paying tuition the same day) and in deferment, a campus
/// job, irregular tutoring
/// income, a monthly transfer from a parent and thin spending. The loans are at a second
/// institution, so their Item carries only loan activity.
library;

import 'package:persona_engine/src/model/persona.dart';
import 'package:persona_engine/src/model/schedule.dart';
import 'package:persona_engine/src/personas/institutions.dart';
import 'package:persona_engine/src/personas/merchants.dart';
import 'package:persona_engine/src/personas/shapes.dart';
import 'package:shared_models/shared_models.dart';

Money _usd(int minor) => Money(minor, 'USD');

const Schedule _semesters = Yearly([MonthDay(1, 12), MonthDay(8, 20)]);

/// The student persona.
final Persona student = Persona(
  id: PersonaId.student,
  currency: 'USD',
  identity: const IdentitySpec(
    names: ['Sam Rivera'],
    phone: '5125550147',
    email: 'sam.rivera@example.com',
    street: '2501 Nueces Street, Unit 12',
    city: 'Austin',
    region: 'TX',
    postalCode: '78705',
  ),
  institutions: const [platypus, gingham],
  accounts: [
    AccountSpec(
      key: 'checking',
      institution: 'platypus',
      type: AccountType.depository,
      subtype: 'checking',
      name: 'Student Checking',
      officialName: 'Platypus Student Checking',
      mask: '6610',
      opening: _usd(85000),
      coverFrom: 'savings',
    ),
    AccountSpec(
      key: 'savings',
      institution: 'platypus',
      type: AccountType.depository,
      subtype: 'savings',
      name: 'Savings',
      officialName: 'Platypus Savings',
      mask: '6628',
      opening: _usd(120000),
      apyBasisPoints: 400,
    ),
    AccountSpec(
      key: 'card',
      institution: 'platypus',
      type: AccountType.credit,
      subtype: 'credit card',
      name: 'Student Card',
      officialName: 'Platypus Student Visa',
      mask: '0472',
      opening: _usd(-18000),
      creditLimit: _usd(100000),
    ),
    const AccountSpec(
      key: 'loan_undergrad',
      institution: 'gingham',
      type: AccountType.loan,
      subtype: 'student',
      name: 'Undergraduate Loan',
      officialName: 'Gingham Student Loan',
      mask: '9031',
    ),
    const AccountSpec(
      key: 'loan_grad',
      institution: 'gingham',
      type: AccountType.loan,
      subtype: 'student',
      name: 'Graduate Loan',
      officialName: 'Gingham Graduate Student Loan',
      mask: '9047',
    ),
  ],
  incomes: [
    IncomeSpec(
      key: 'campus_job',
      account: 'checking',
      payer: const Payee(
        'STATE UNIV PAYROLL DIR DEP',
        'State University',
        'INCOME_SALARY',
      ),
      schedule: Biweekly(
        LocalDate(2024, 1, 12),
        businessDay: BusinessDayRule.rollBack,
      ),
      amount: _usd(64000),
      varianceBasisPoints: 1500,
    ),
    IncomeSpec(
      key: 'tutoring',
      account: 'checking',
      payer: const Payee('WYZANT TUTOR PAYMENT', 'Wyzant', 'INCOME_CONTRACTOR'),
      schedule: const Weekly(DateTime.friday),
      amount: _usd(9000),
      varianceBasisPoints: 5000,
      skipPermille: 450,
    ),
    IncomeSpec(
      key: 'parent',
      account: 'checking',
      payer: const Payee(
        'VENMO CASHOUT FROM M RIVERA',
        'Venmo',
        'TRANSFER_IN_TRANSFER_IN_FROM_APPS',
      ),
      schedule: const Monthly(1),
      amount: _usd(40000),
    ),
  ],
  bills: [
    BillSpec(
      key: 'rent',
      account: 'checking',
      payee: const Payee(
        'COLLEGEVIEW APTS RENT',
        'Collegeview Apartments',
        'RENT_AND_UTILITIES_RENT',
      ),
      schedule: const Monthly(1, businessDay: BusinessDayRule.rollForward),
      amount: _usd(72500),
    ),
    BillSpec(
      key: 'phone',
      account: 'card',
      payee: mintMobile,
      schedule: const Monthly(9),
      amount: _usd(3000),
    ),
  ],
  subscriptions: [
    BillSpec(
      key: 'spotify',
      account: 'card',
      payee: spotify,
      schedule: const Monthly(21),
      amount: _usd(599),
    ),
  ],
  loans: [
    LoanSpec(
      key: 'loan_undergrad',
      account: 'loan_undergrad',
      kind: LoanKind.student,
      schedule: const Monthly(28),
      aprBasisPoints: 499,
      originationMonthsBefore: 86,
      originationPrincipal: _usd(2700000),
      termMonths: 126,
      nonRepaymentMonths: 6,
      loanName: 'Gingham Undergraduate Direct Loan',
      payFrom: 'checking',
      paymentPayee: const Payee(
        'GINGHAM STUDENT LN PAYMENT',
        'First Gingham Credit Union',
        'LOAN_PAYMENTS_STUDENT_LOAN_PAYMENT',
      ),
    ),
    LoanSpec(
      key: 'loan_grad',
      account: 'loan_grad',
      kind: LoanKind.student,
      schedule: const Monthly(28),
      aprBasisPoints: 653,
      originationMonthsBefore: 26,
      originationPrincipal: _usd(650000),
      termMonths: 150,
      nonRepaymentMonths: 30,
      loanName: 'Gingham Graduate Direct Loan',
      deferred: true,
    ),
  ],
  disbursements: [
    DisbursementSpec(
      key: 'grad_disbursement',
      loan: 'loan_grad',
      to: 'checking',
      schedule: _semesters,
      amount: _usd(650000),
      payee: const Payee(
        'GINGHAM STUDENT LN DISBURSEMENT',
        null,
        'LOAN_DISBURSEMENTS_STUDENT',
      ),
      paysOut: const Payee(
        'STATE UNIV BURSAR PAYMENT',
        'State University',
        'GENERAL_SERVICES_EDUCATION',
      ),
      paysOutAmount: _usd(540000),
    ),
  ],
  cards: [
    CardSpec(
      account: 'card',
      payFrom: 'checking',
      closeDay: 3,
      dueAfterDays: 21,
      payBasisPoints: 10000,
      aprBasisPoints: 2399,
      minimumBasisPoints: 300,
      minimumFloor: _usd(2500),
      keepAbove: _usd(20000),
      paymentPayee: const Payee(
        'PLATYPUS CARD PAYMENT',
        null,
        'LOAN_PAYMENTS_CREDIT_CARD_PAYMENT',
      ),
    ),
  ],
  transfers: [
    TransferSpec(
      key: 'savings',
      from: 'checking',
      to: 'savings',
      schedule: const Monthly(15),
      amount: _usd(5000),
      keepAbove: _usd(40000),
      outPayee: const Payee(
        'ONLINE TRANSFER TO SAVINGS',
        null,
        'TRANSFER_OUT_SAVINGS',
      ),
      inPayee: const Payee(
        'ONLINE TRANSFER FROM CHECKING',
        null,
        'TRANSFER_IN_SAVINGS',
      ),
      sweepAbove: _usd(450000),
    ),
  ],
  spending: const [
    SpendingSpec(
      key: 'groceries',
      account: 'checking',
      merchants: [traderJoes, aldi],
      rateMilli: 250,
      weekly: weekendHeavy,
      seasonal: flatYear,
      postLagDays: 1,
    ),
    SpendingSpec(
      key: 'coffee',
      account: 'card',
      merchants: [starbucks],
      rateMilli: 280,
      weekly: weekdays,
      seasonal: flatYear,
      postLagDays: 1,
    ),
    SpendingSpec(
      key: 'fast_food',
      account: 'card',
      merchants: [chipotle, mcdonalds],
      rateMilli: 250,
      weekly: weekendHeavy,
      seasonal: flatYear,
      postLagDays: 1,
    ),
    SpendingSpec(
      key: 'transit',
      account: 'checking',
      merchants: [clipper],
      rateMilli: 220,
      weekly: weekdays,
      seasonal: flatYear,
    ),
    SpendingSpec(
      key: 'books',
      account: 'card',
      merchants: [bookstore],
      rateMilli: 12,
      weekly: weekdays,
      seasonal: semesterStarts,
      postLagDays: 1,
    ),
    SpendingSpec(
      key: 'games',
      account: 'card',
      merchants: [steam],
      rateMilli: 15,
      weekly: weekendHeavy,
      seasonal: holidayRetail,
      postLagDays: 1,
    ),
    SpendingSpec(
      key: 'convenience',
      account: 'checking',
      merchants: [seven11, bevmo],
      rateMilli: 60,
      weekly: weekendOutings,
      seasonal: flatYear,
    ),
  ],
  anomalyAccount: 'card',
  anomalyMerchants: oneOffMerchants,
);
