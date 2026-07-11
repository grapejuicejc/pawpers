import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../app_theme.dart';
import '../widgets/image_placeholder.dart';
import '../widgets/primary_btn.dart';

class MyPetsScreen extends StatefulWidget {
  const MyPetsScreen({super.key});

  @override
  State<MyPetsScreen> createState() => _MyPetsScreenState();
}

class _MyPetsScreenState extends State<MyPetsScreen> {
  bool _isLoading = false;

  // Placeholder data. DB (Supabase): replace with
  // SupabaseService.instance.fetchMyPets() in initState.
  List<Pet> _pets = [
    Pet(
      id: 'p1',
      ownerId: 'u1',
      name: 'Max',
      breed: 'Golden Retriever',
      description: 'Loves long walks and belly rubs.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);

    // DB (Supabase):
    // final pets = await SupabaseService.instance.fetchMyPets();

    await Future.delayed(const Duration(milliseconds: 300)); // placeholder delay

    if (!mounted) return;
    setState(() => _isLoading = false);
    // setState(() => _pets = pets); // uncomment once fetching real data
  }

  Future<void> _addAnotherPet() async {
    final result = await showDialog<Pet>(
      context: context,
      builder: (context) => const _AddPetDialog(),
    );
    if (result == null) return;

    // DB (Supabase):
    // await SupabaseService.instance.addPet(result);

    setState(() => _pets = [..._pets, result]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Pets')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _pets.isEmpty
                          ? const Center(
                              child: Text(
                                'No pets added yet.',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _pets.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, i) => _PetCard(
                                pet: _pets[i],
                                onDelete: () {
                                  // DB (Supabase): await SupabaseService.instance.deletePet(pet.id);
                                  setState(() => _pets = List.of(_pets)..removeAt(i));
                                },
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(label: '+ Add Another Pet', onPressed: _addAnotherPet),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onDelete;

  const _PetCard({required this.pet, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ImagePlaceholderBox(height: 50, width: 50, borderRadius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(pet.breed, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // TODO: open edit-pet dialog (reuse _AddPetDialog pre-filled)
                },
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
              ),
            ],
          ),
          if (pet.description != null) ...[
            const SizedBox(height: 8),
            Text(pet.description!, style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

/// Simple dialog used to add a new pet. Kept minimal since the wireframe
/// only shows the "My Pets" list + "Add Another Pet" button, not a full
/// add-pet form screen.
class _AddPetDialog extends StatefulWidget {
  const _AddPetDialog();

  @override
  State<_AddPetDialog> createState() => _AddPetDialogState();
}

class _AddPetDialogState extends State<_AddPetDialog> {
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Another Pet'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Pet name')),
          const SizedBox(height: 10),
          TextField(controller: _breedController, decoration: const InputDecoration(hintText: 'Breed')),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(hintText: 'Description (optional)'),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty || _breedController.text.trim().isEmpty) return;
            Navigator.of(context).pop(
              Pet(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                ownerId: 'u1', // DB (Supabase): use current user's id
                name: _nameController.text.trim(),
                breed: _breedController.text.trim(),
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
