/// The persona registry.
library;

import 'package:persona_engine/src/model/persona.dart';
import 'package:persona_engine/src/personas/family.dart';
import 'package:persona_engine/src/personas/renter.dart';
import 'package:persona_engine/src/personas/small_business.dart';
import 'package:persona_engine/src/personas/student.dart';

/// The persona [id] names.
Persona personaFor(PersonaId id) => switch (id) {
  PersonaId.renter => renter,
  PersonaId.family => family,
  PersonaId.student => student,
  PersonaId.smallBusiness => smallBusiness,
};
