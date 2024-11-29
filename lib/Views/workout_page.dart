import 'package:flutter/material.dart';
import 'package:flutter_searchable_dropdown/flutter_searchable_dropdown.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:prototype_three/Components/bottom_sheet_3.dart';
import 'package:prototype_three/Components/exercise_card.dart';
import 'package:prototype_three/Controllers/exercise_box_controller.dart';
import 'package:prototype_three/Model/Exercise.dart';
import 'package:prototype_three/Model/Workout.dart';
import 'package:prototype_three/Model/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage(
      {super.key, required this.workout, required this.justCreated});

  final TestWorkout workout;
  final bool justCreated;

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final TextEditingController textController = TextEditingController();

  

  @override
  Widget build(BuildContext context) {
    Future<TestWorkout?> getMostRecentWorkout() async {
      try {
        // Fetch data from the workouts table as a stream
        final workoutStream = Supabase.instance.client
            .from('workouts')
            .stream(primaryKey: ['id']);

        // Convert the first event of the stream to a list of TestWorkout objects
        final workouts = await workoutStream.first;

        // Map the raw data into TestWorkout objects
        final testWorkouts =
            workouts.map((workout) => TestWorkout.frommap(workout)).toList();

        // Sort the workouts by date in descending order (most recent first)
        testWorkouts.sort((a, b) => b.date.compareTo(a.date));

        // Return the most recent workout or null if the list is empty
        return testWorkouts.isNotEmpty ? testWorkouts.first : null;
      } catch (e) {
        // Handle errors (e.g., log them)
        print('Error fetching most recent workout: $e');
        return null;
      }
    }

    final exerciseStream = Supabase.instance.client
        .from('exercises')
        .stream(primaryKey: ['id']).eq(
            'workout_id',
            widget.justCreated
                ? getMostRecentWorkout()
                : widget.workout.workoutId);

    return Scaffold(
        appBar: _buildAppBar(context),
        floatingActionButton: _buildFloatingActionButton(context),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: exerciseStream, // Stream of exercises from Supabase
          builder: (context, snapshot) {
            // Future.delayed(
            //   const Duration(seconds: 3),
            //   () => 100,
            // ).then((value) {
            //   print('The value is $value.'); // Prints later, after 3 seconds.
            // });

            // print('Waiting for a value...'); // Prints first.

            if (!widget.justCreated) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return GetBuilder<ExerciseController>(
                init: ExerciseController(), // Initialize the controller
                builder: (controller) {
                  final exercises = snapshot.data!
                      .map((json) => TestExercise.fromJson(json))
                      .toList();

                  return ListView.builder(
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];

                      return GestureDetector(
                        onTap: () async {
                          await exercise.fetchSets();
                        },
                        child: ExerciseCard(
                            exercise: exercise,
                            onTap: () => _showBottomSheet(context, exercise)),
                      );
                    },
                  );
                },
              );
            }
            return const Center(child: Text("just created"));
          },
        ));
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
          "${DateFormat.MMMd().format(widget.workout.date)} (${widget.workout.name})"),
      backgroundColor: Colors.teal,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _confirmDeleteWorkout(context),
        ),
      ],
    );
  }

  FloatingActionButton _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Colors.teal,
      onPressed: () => _showAddExerciseDialog(context),
      child: const Icon(Icons.add),
    );
  }

  // create exercise from dropdown
  String? selectedExercise;
  final List<String> exerciseNames = [
    "Bench Press",
    "Pull Ups",
    "Lat pull Down",
    "T-Bar Rows",
    "Deadlift",
    "Squat",
    // Add more exercise names here
  ];

  Future<void> createExercise(TestWorkout workout) async {
    final newExercise = TestExercise(name: selectedExercise!);
    await ExerciseDatabase().creatExercise(newExercise, workout.workoutId);
    // Get.back();
  }

  void _showAddExerciseDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Add Exercise"),
            content: SizedBox(
              height: 70,
              child: SearchableDropdown.single(
                items: exerciseNames.map((exercise) {
                  return DropdownMenuItem<String>(
                    value: exercise,
                    child: Text(exercise),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedExercise = value;
                  });
                },
                hint: const Text('Choose Exercise'),
                isExpanded: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  // Optionally clear selection if needed
                  setState(() {
                    selectedExercise = null;
                  });
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (selectedExercise != null) {
                    await createExercise(widget.workout);
                    Navigator.of(context).pop();
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        });
  }

  void _confirmDeleteWorkout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Workout"),
          content: const Text("This action is not reversible!"),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                WorkoutDatabase().deleteWorkout(widget.workout);
                Get.back(); // Close dialog
                Get.back(); // Go back to previous screen
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _showBottomSheet(BuildContext context, TestExercise exercise) {
    showModalBottomSheet(
      context: context,
      builder: (context) => CustomBottomSheet3(exercise: exercise),
    );
  }
}
