import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TaskListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController taskController = TextEditingController();
  final CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');
  final CollectionReference subTasks = FirebaseFirestore.instance.collection('subtasks');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: taskController, decoration: InputDecoration(hintText: 'Enter task name'))),
                ElevatedButton(
                  child: Text('Add'),
                  onPressed: () {
                    if (taskController.text.isNotEmpty) {
                      tasks.add({
                        'name': taskController.text,
                        'completed': false,
                      });
                      taskController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: tasks.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    return ExpansionTile(
                      leading: Checkbox(
                        value: doc['completed'],
                        onChanged: (val) {
                          tasks.doc(doc.id).update({'completed': val});
                        },
                      ),
                      title: Text(doc['name'], style: TextStyle(decoration: doc['completed'] ? TextDecoration.lineThrough : null)),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => tasks.doc(doc.id).delete(),
                      ),
                      children: [
                        SubTaskList(parentTaskId: doc.id),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: AddSubTaskField(parentTaskId: doc.id),
                        )
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class SubTaskList extends StatelessWidget {
  final String parentTaskId;
  SubTaskList({required this.parentTaskId});

  @override
  Widget build(BuildContext context) {
    final CollectionReference subTasks = FirebaseFirestore.instance.collection('subtasks');
    return StreamBuilder(
      stream: subTasks.where('parentTaskId', isEqualTo: parentTaskId).snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        return Column(
          children: snapshot.data!.docs.map((doc) {
            return ListTile(
              leading: Checkbox(
                value: doc['completed'],
                onChanged: (val) {
                  subTasks.doc(doc.id).update({'completed': val});
                },
              ),
              title: Text(doc['name']),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => subTasks.doc(doc.id).delete(),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class AddSubTaskField extends StatefulWidget {
  final String parentTaskId;
  AddSubTaskField({required this.parentTaskId});

  @override
  _AddSubTaskFieldState createState() => _AddSubTaskFieldState();
}

class _AddSubTaskFieldState extends State<AddSubTaskField> {
  final TextEditingController subTaskController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: subTaskController,
            decoration: InputDecoration(hintText: 'Enter sub-task'),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () {
            if (subTaskController.text.isNotEmpty) {
              FirebaseFirestore.instance.collection('subtasks').add({
                'name': subTaskController.text,
                'completed': false,
                'parentTaskId': widget.parentTaskId,
              });
              subTaskController.clear();
            }
          },
        )
      ],
    );
  }
}


