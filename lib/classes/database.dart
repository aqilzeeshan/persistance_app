import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

/*
DatabaseFileRoutines class handles locating the device's local document directory path through the
path_provider package. You used the File class to handle the saving and reading of the database file
by importing the dart:io library. The file is text-based containing the key/value pair of JSON objects.
* */
class DatabaseFileRoutines {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/local_persistance.json');
  }

  Future<String> readJournals() async {
    try {
      final file = await _localFile;
      if (!file.existsSync()) {
        print("File does not Exist: ${file.absolute}");
        await writeJournals('{"journals":[]}');
      }

      //Read the file
      String contents = await file.readAsString();
      return contents;
    } catch (e) {
      print("error readJournals: $e");
      return "";
    }
  }

  Future<File> writeJournals(String json) async {
    final file = await _localFile;
    return file.writeAsString('$json');
  }
}

/*
Create two method that call the Database class to handle the JSON decode and encode for the entire
database. Create the databaseFromJson(String str) method returning a Database by passing it the JSOn string.
By using json.decode(str), it parses the JSOn string and return a JSON object.
* */
Database databaseFromJson(String str) {
  final dataFromJson = json.decode(str);
  return Database.fromJson(dataFromJson);
}

/*
Create the databaseToJson(Database data) method returning a String. By using the json.encode(dataToJson),
it parses the values to a JSON string.
* */
String databaseToJson(Database data) {
  final dataToJson = data.toJson();
  return json.encode(dataToJson);
}

/*
The Database class uses json.encode and json.decode to serialize and deserialize JSON objects
by importing the dart:convert library.

You use the Database.fromJson named constructor to retrieve and map the JSON objects to a List<Journal>.

You use the toJson method to convert the List<Journal> to JSON objects.
* */

//Database class contains a list of journals
class Database {
  List<Journal> journal;

  Database({this.journal});
//To retrieve and map the JSON objects to a List<Journal> (list of Journal classes), create the
// factory Database.fromJson() named constructor. Note that the factory constructor does not
// always create a new instance but might return an instance from a cache. The constructor takes
// the arguments of Map<String, dynamic> which maps the String key with a dynamic value,
// the JSON key/value pair. The constructor returns the List<Journal> by taking the JSON 'journals'
  //object containing each field such as the id, date, mood and note.
  factory Database.fromJson(Map<String, dynamic> json) => Database(
        journal: List<Journal>.from(
            json["journals"].map((x) => Journal.fromJson(x))),
      );

  //To convert the List<Journal> to JSON object, create the toJson object, create the toJson method
  //that parses each Journal class to JSON objects.
  Map<String, dynamic> toJson() => {
        "journals": List<dynamic>.from(journal.map((x) => x.toJson())),
      };
}

/*
The Journal class is responsible for tracking individual journal entries through the String id,date,
mood, and note variables.

You use the Journal.fromJson() named constructor to take the argument of Map<String,dynamic>, which
maps the String key with a dynamic value, the JSON key/value pair.

You use the toJson method to convert the Journal class into a JSON object. 
* */

class Journal {
  String id;
  String date;
  String mood;
  String note;

  Journal({
    this.id,
    this.date,
    this.mood,
    this.note,
  });

//To retrieve and convert the JSON object to a Journal class, create the factory Journal.fromJson()
//named constructor. The constructor takes the argument of Map<String, dynamic> which maps the
//String key with a dynamic value, the JSON key/value pair
  factory Journal.fromJson(Map<String, dynamic> json) => Journal(
      id: json["id"],
      date: json["date"],
      mood: json["mood"],
      note: json["note"]);

//To convert the Journal class to a JSON object, create the toJson() method
// that parses the Journal class to a JSON object
  Map<String, dynamic> toJson() => {
        "id": id,
        "date": date,
        "mood": mood,
        "note": note,
      };
}
/*
The JournalEdit class is used to pass data between pages. You declared a String action variable and
a Journal journal variable. The action variable passes an action to 'Save' or 'Cancel', editing an entry.

* */

/*
JournalEdit class that is responsible for passing the 'action' and a 'journal' entry between pages.
Add a String action variable and a Journal journal variable. Add the default JournalEdit constructor
* */
class JournalEdit {
  String action;
  Journal journal;
  JournalEdit({this.action, this.journal});
}
