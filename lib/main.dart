import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:persistanceapp/classes/database.dart';
import 'package:intl/intl.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Local Persistance',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        bottomAppBarColor: Colors.blue,
      ),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Database _database;

  Future<List<Journal>> _loadJournals() async {
    await DatabaseFileRoutines().readJournals().then((journalsJson) {
      _database = databaseFromJson(journalsJson);
      _database.journal
          .sort((comp1, comp2) => comp2.date.compareTo(comp1.date));
    });
    return _database.journal;
  }

  //Add or Edit Journal Entry and call the Show Entry Dialog

  void _addOrEditJournal({bool add, int index, Journal journal}) async {
    JournalEdit _journalEdit = JournalEdit(action: '', journal: journal);
    _journalEdit = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditEntry(
                  add: add,
                  index: index,
                  journalEdit: _journalEdit,
                ),
            fullscreenDialog: true));

    switch (_journalEdit.action) {
      case 'Save':
        if (add) {
          setState(() {
            _database.journal.add(_journalEdit.journal);
          });
        } else {
          setState(() {
            _database.journal[index] = _journalEdit.journal;
          });
        }
        DatabaseFileRoutines().writeJournals(databaseToJson((_database)));
        break;
      case 'Cancel':
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Local Persistance'),
      ),
      body: FutureBuilder(
        initialData: [],
        future: _loadJournals(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return !snapshot.hasData
              ? Center(child: CircularProgressIndicator())
              : _buildListViewSeparated(snapshot);

          return Center(child: CircularProgressIndicator());
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Journal Entry',
        child: Icon(Icons.add),
        onPressed: () async {
          _addOrEditJournal(add: true, index: -1, journal: Journal());
        },
      ),
    );
  }

  // Build the ListView with Separator
  Widget _buildListViewSeparated(AsyncSnapshot snapshot) {
    return ListView.separated(
      itemCount: snapshot.data.length,
      itemBuilder: (BuildContext context, int index) {
        String _titleDate = DateFormat.yMMMd()
            .format(DateTime.parse(snapshot.data[index].date));
        String _subtitle =
            snapshot.data[index].mood + "\n" + snapshot.data[index].note;
        return Dismissible(
          key: Key(snapshot.data[index].id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 16.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          child: ListTile(
            leading: Column(
              children: <Widget>[
                Text(
                  DateFormat.d()
                      .format(DateTime.parse(snapshot.data[index].date)),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 32.0,
                      color: Colors.blue),
                ),
                Text(DateFormat.E()
                    .format(DateTime.parse(snapshot.data[index].date))),
              ],
            ),
            title: Text(
              _titleDate,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(_subtitle),
            onTap: () async {
              _addOrEditJournal(
                add: false,
                index: index,
                journal: snapshot.data[index],
              );
            },
          ),
          onDismissed: (direction) {
            setState(() {
              _database.journal.removeAt(index);
            });
            DatabaseFileRoutines().writeJournals(databaseToJson(_database));
          },
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return Divider(
          color: Colors.grey,
        );
      },
    );
  }
}

class EditEntry extends StatefulWidget {
  final bool add;
  final int index;
  final JournalEdit journalEdit;

  const EditEntry({Key key, this.add, this.index, this.journalEdit})
      : super(key: key);

  @override
  _EditEntryState createState() => _EditEntryState();
}

class _EditEntryState extends State<EditEntry> {
  JournalEdit _journalEdit;
  String _title;
  DateTime _selectedDate;
  TextEditingController _moodController = TextEditingController();
  TextEditingController _noteController = TextEditingController();
  FocusNode _moodFocus = FocusNode();
  FocusNode _noteFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    _journalEdit =
        JournalEdit(action: 'Cancel', journal: widget.journalEdit.journal);
    _title = widget.add ? 'Add' : 'Edit';
    _journalEdit.journal = widget.journalEdit.journal;
    if (widget.add) {
      _selectedDate = DateTime.now();
      _moodController.text = '';
      _noteController.text = '';
    } else {
      _selectedDate = DateTime.parse(_journalEdit.journal.date);
      _moodController.text = _journalEdit.journal.mood;
      _noteController.text = _journalEdit.journal.note;
    }
  }

  @override
  void dispose() {
    _moodController.dispose();
    _noteController.dispose();
    _moodFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  //Date Picker
  Future<DateTime> _selectDate(DateTime selectedDate) async {
    DateTime _initialDate = selectedDate;

    final DateTime _pickedDate = await showDatePicker(
      context: context,
      initialDate: _initialDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (_pickedDate != null) {
      selectedDate = DateTime(
          _pickedDate.year,
          _pickedDate.month,
          _pickedDate.day,
          _initialDate.hour,
          _initialDate.minute,
          _initialDate.second,
          _initialDate.millisecond,
          _initialDate.microsecond);
    }

    return selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_title Entry'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              FlatButton(
                padding: EdgeInsets.all(0.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 22.0,
                      color: Colors.black54,
                    ),
                    SizedBox(
                      width: 16.0,
                    ),
                    Text(
                      DateFormat.yMMMEd().format(_selectedDate),
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.black54,
                    ),
                  ],
                ),
                onPressed: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  DateTime _pickerDate = await _selectDate(_selectedDate);
                  setState(() {
                    _selectedDate = _pickerDate;
                  });
                },
              ),
              TextField(
                controller: _moodController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                focusNode: _moodFocus,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Mood',
                  icon: Icon(Icons.mood),
                ),
                onSubmitted: (submitted) {
                  FocusScope.of(context).requestFocus(_noteFocus);
                },
              ),
              TextField(
                controller: _noteController,
                textInputAction: TextInputAction.newline,
                focusNode: _noteFocus,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Note',
                  icon: Icon(Icons.subject),
                ),
                maxLines: null,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FlatButton(
                    child: Text('Cancel'),
                    color: Colors.grey.shade100,
                    onPressed: () {
                      _journalEdit.action = 'Cancel';
                      Navigator.pop(context, _journalEdit);
                    },
                  ),
                  SizedBox(width: 8.0),
                  FlatButton(
                    child: Text('Save'),
                    color: Colors.lightGreen.shade100,
                    onPressed: () {
                      _journalEdit.action = 'Save';
                      String _id = widget.add
                          ? Random().nextInt(9999999).toString()
                          : _journalEdit.journal.id;
                      _journalEdit.journal = Journal(
                        id: _id,
                        date: _selectedDate.toString(),
                        mood: _moodController.text,
                        note: _noteController.text,
                      );
                      Navigator.pop(context, _journalEdit);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
