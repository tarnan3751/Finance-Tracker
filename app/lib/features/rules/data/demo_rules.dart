/// The demo flavor's rules: two per persona, written against that persona's own
/// merchants and categories so each matches some of its demo transactions. Data only;
/// they use tags and the system categories (`plaid:<CODE>`), which exist in every demo.
library;

import 'package:persona_engine/persona_engine.dart' show PersonaId;
import 'package:shared_models/shared_models.dart';

/// The two rules of [persona]'s demo.
List<Rule> demoRules(PersonaId persona) => switch (persona) {
  PersonaId.renter => [
    _rule(
      'demo-rule-coffee',
      'Coffee runs',
      0,
      _merchant('Starbucks'),
      _tag('coffee'),
    ),
    _rule(
      'demo-rule-gig',
      'Gig income',
      1,
      _plaid('INCOME_GIG_ECONOMY'),
      _tag('gig'),
    ),
  ],
  PersonaId.family => [
    _rule(
      'demo-rule-warehouse',
      'Warehouse runs',
      0,
      _merchant('Costco'),
      _category('plaid:FOOD_AND_DRINK_GROCERIES'),
      _tag('bulk'),
    ),
    _rule(
      'demo-rule-kids',
      'Kids outings',
      1,
      _merchant('Chuck E. Cheese'),
      _tag('kids'),
    ),
  ],
  PersonaId.student => [
    _rule(
      'demo-rule-books',
      'Textbooks',
      0,
      _merchant('Bookstore'),
      _tag('school'),
    ),
    _rule(
      'demo-rule-coffee',
      'Coffee runs',
      1,
      _merchant('Starbucks'),
      _tag('coffee'),
    ),
  ],
  PersonaId.smallBusiness => [
    _rule(
      'demo-rule-shipping',
      'Shipping',
      0,
      _plaid('GENERAL_SERVICES_POSTAGE_AND_SHIPPING'),
      _tag('business'),
    ),
    _rule(
      'demo-rule-rides',
      'Rides',
      1,
      _merchant('Uber'),
      _category('plaid:TRANSPORTATION_TAXIS_AND_RIDE_SHARES'),
    ),
  ],
};

Rule _rule(
  String id,
  String name,
  int position,
  RuleCondition condition,
  RuleAction action, [
  RuleAction? second,
]) => Rule(
  id: id,
  name: name,
  position: position,
  conditions: [condition],
  actions: [action, ?second],
);

RuleCondition _merchant(String text) =>
    RuleCondition(kind: RuleConditionKind.merchantContains, text: text);

RuleCondition _plaid(String code) =>
    RuleCondition(kind: RuleConditionKind.plaidCategory, text: code);

RuleAction _tag(String tag) =>
    RuleAction(kind: RuleActionKind.addTag, value: tag);

RuleAction _category(String id) =>
    RuleAction(kind: RuleActionKind.setCategory, value: id);
