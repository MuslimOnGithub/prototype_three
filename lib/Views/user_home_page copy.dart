import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:intl/intl.dart';
import 'package:prototype_three/Model/Workout.dart';
import 'package:prototype_three/Model/app_database.dart';
import 'package:prototype_three/Views/workout_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:path/path.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final workoutDatabase = WorkoutDatabase();

  final textController = TextEditingController();

  final _workoutStream =
      Supabase.instance.client.from('workout').stream(primaryKey: ['id']);

  _appBar(color) {
    return AppBar(
      title: const Text("Home"),
      backgroundColor: color,
    );
  }

  Future<TestWorkout> createWorkout() async {
    // Creat new workout
    final newWorkout =
        TestWorkout(name: textController.text, date: DateTime.now());
    workoutDatabase.creatWorkoutTest(newWorkout);
    textController.clear();

    return newWorkout;
  }

  void updateWorkoutName(TestWorkout workout) {
    //prefill the text controller with the existing note
    textController.text = workout.name;
    showDialog(
        context: context,
        builder: ((context) => AlertDialog(
              title: const Text("Workout"),
              content: TextField(
                controller: textController,
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Get.back();
                      textController.clear();
                    },
                    child: const Text("Cancel")),
                TextButton(
                  onPressed: () {
                    workoutDatabase.updateWorkoutName(
                        workout, textController.text);
                    Navigator.pop(context);
                    textController.clear();
                  },
                  child: const Text("Update"),
                )
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    Color color = Colors.teal;

    return Scaffold(
      appBar: _appBar(color),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: ((context) => AlertDialog(
                    title: const Text("New Workout"),
                    content: TextField(
                      controller: textController,
                    ),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Get.back();
                            textController.clear();
                          },
                          child: const Text("Cancel")),
                      TextButton(
                        onPressed: () async {
                          // await createWorkout();
                          var newWorkout = await createWorkout();

                          Get.back();

                          Get.to(() => WorkoutPage(
                                workout: newWorkout,
                                justCreated: true,
                              ));
                        },
                        child: const Text("Save"),
                      )
                    ],
                  )));
        },
        backgroundColor: color,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _workoutStream,
          builder: ((context, snapshot) {
            // Loading
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            // Loaded
            final workouts = snapshot.data;
            // final workouts = TestWorkout.frommap(data);

            return ListView.builder(
                itemCount: workouts!.length,
                itemBuilder: ((context, index) {
                  final workout = TestWorkout.frommap(workouts[index]);

                  final workoutName = workout.name;

                  return GestureDetector(
                    onTap: () {
                      Get.to(WorkoutPage(
                        workout: workout,
                        justCreated: false,
                      ));
                    },
                    child: Card(
                      child: ListTile(
                          title: Text(
                            workoutName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          // subtitle: Text(workout),
                          trailing:
                              Text(DateFormat.MMMd().format(workout.date))),
                    ),
                  );
                }));
          })),
    );
  }
}
