// This file previously contained Isar ORM schemas.
// The project uses sqflite (OmegaDatabase) as the local database instead.
// All schema/query logic is in omega_database.dart.
//
// This file is kept as a compatibility shim so that existing imports of
// 'isar_schema.dart' continue to compile while the codebase is migrated.

export 'omega_database.dart';
