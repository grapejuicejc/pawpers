import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/pet.dart';
import '../../app_theme.dart';
import '../../widgets/image_placeholder.dart';
import '../../widgets/primary_btn.dart';

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
      sex: 'Male',
      age: 3,
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

    await Future.delayed(
      const Duration(milliseconds: 300),
    ); // placeholder delay

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
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child:
                            _pets.isEmpty
                                ? const Center(
                                  child: Text(
                                    'No pets added yet.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                )
                                : ListView.separated(
                                  itemCount: _pets.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 12),
                                  itemBuilder:
                                      (context, i) => _PetCard(
                                        pet: _pets[i],
                                        onEdit: () async {
                                          final result = await showDialog<Pet>(
                                            context: context,
                                            builder:
                                                (_) => _EditPetDialog(
                                                  pet: _pets[i],
                                                ),
                                          );
                                          if (result == null) return;
                                          // DB (Supabase): await SupabaseService.instance.updatePet(result);
                                          setState(
                                            () =>
                                                _pets = List.of(_pets)
                                                  ..[i] = result,
                                          );
                                        },
                                        onDelete: () async {
                                          final confirmed = await showDialog<
                                            bool
                                          >(
                                            context: context,
                                            builder:
                                                (_) => AlertDialog(
                                                  title: Text(
                                                    'Delete Pet',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  content: Text(
                                                    'Remove ${_pets[i].name}?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.of(
                                                            context,
                                                          ).pop(false),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                AppColors
                                                                    .danger,
                                                          ),
                                                      onPressed:
                                                          () => Navigator.of(
                                                            context,
                                                          ).pop(true),
                                                      child: const Text(
                                                        'Delete',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          );
                                          if (confirmed != true) return;
                                          // DB (Supabase): await SupabaseService.instance.deletePet(_pets[i].id);
                                          setState(
                                            () =>
                                                _pets = List.of(_pets)
                                                  ..removeAt(i),
                                          );
                                        },
                                      ),
                                ),
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: '+ Add Another Pet',
                        onPressed: _addAnotherPet,
                      ),
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
  final VoidCallback onEdit;

  const _PetCard({
    required this.pet,
    required this.onDelete,
    required this.onEdit,
  });

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
              ImagePlaceholderBox(
                height: 50,
                width: 50,
                borderRadius: 8,
                imageFile: pet.imageFile,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      pet.breed,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.danger,
                ),
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
  final _sexController = TextEditingController();
  final _ageController = TextEditingController();
  File? _imageFile;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Another Pet'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: ImagePlaceholderBox(
                height: 80,
                width: 80,
                borderRadius: 8,
                imageFile: _imageFile,
                icon: Icons.add_a_photo_outlined,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Pet name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _breedController,
              decoration: const InputDecoration(hintText: 'Breed'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _sexController,
              decoration: const InputDecoration(
                hintText: 'Sex (e.g. Male / Female)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Age'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty ||
                _breedController.text.trim().isEmpty ||
                _sexController.text.trim().isEmpty ||
                _ageController.text.trim().isEmpty)
              return;
            Navigator.of(context).pop(
              Pet(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                ownerId: 'u1',
                name: _nameController.text.trim(),
                breed: _breedController.text.trim(),
                sex: _sexController.text.trim(),
                age: int.tryParse(_ageController.text.trim()) ?? 0,
                imageFile: _imageFile,
                description:
                    _descriptionController.text.trim().isEmpty
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
    _sexController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class _EditPetDialog extends StatefulWidget {
  final Pet pet;
  const _EditPetDialog({required this.pet});

  @override
  State<_EditPetDialog> createState() => _EditPetDialogState();
}

class _EditPetDialogState extends State<_EditPetDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _sexController;
  late final TextEditingController _ageController;
  late final TextEditingController _descriptionController;
  File? _imageFile;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet.name);
    _breedController = TextEditingController(text: widget.pet.breed);
    _sexController = TextEditingController(text: widget.pet.sex);
    _ageController = TextEditingController(text: widget.pet.age.toString());
    _descriptionController = TextEditingController(
      text: widget.pet.description ?? '',
    );
    _imageFile = widget.pet.imageFile;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Edit Pet',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: ImagePlaceholderBox(
                height: 80,
                width: 80,
                borderRadius: 8,
                imageFile: _imageFile,
                icon: Icons.add_a_photo_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Pet name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _breedController,
              decoration: const InputDecoration(labelText: 'Breed'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sexController,
              decoration: const InputDecoration(
                labelText: 'Sex (e.g. Male / Female)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty ||
                _breedController.text.trim().isEmpty ||
                _sexController.text.trim().isEmpty ||
                _ageController.text.trim().isEmpty)
              return;
            Navigator.of(context).pop(
              Pet(
                id: widget.pet.id,
                ownerId: widget.pet.ownerId,
                name: _nameController.text.trim(),
                breed: _breedController.text.trim(),
                sex: _sexController.text.trim(),
                age: int.tryParse(_ageController.text.trim()) ?? widget.pet.age,
                imageFile: _imageFile,
                description:
                    _descriptionController.text.trim().isEmpty
                        ? null
                        : _descriptionController.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _sexController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
