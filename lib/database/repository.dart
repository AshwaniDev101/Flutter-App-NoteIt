class DatabaseRepository
{
  DatabaseRepository._();
  static final DatabaseRepository instance = DatabaseRepository._();

  Future<void> insertNote(dynamic note) async {
  }

  Future<List<dynamic>> getNotes() async {
    return [];
  }

  Future<void> deleteNote(int id) async {
  }

  Future<void> updateNote(dynamic note) async {
  }
}