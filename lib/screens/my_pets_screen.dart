import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/pet.dart';
import '../../app_theme.dart';
import '../../widgets/primary_btn.dart';
import '../../services/pet_service.dart';

class MyPetsScreen extends StatefulWidget {
  const MyPetsScreen({super.key});

  @override
  State<MyPetsScreen> createState() => _MyPetsScreenState();
}

class _MyPetsScreenState extends State<MyPetsScreen> {
  bool _isLoading = false;

  List<Pet> _pets = [];

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  // ============================================================
  // LOAD PETS
  // ============================================================

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);

    try {
      final pets = await PetService.instance.fetchMyPets();

      if (!mounted) return;

      setState(() {
        _pets = pets;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load pets: $e')));
    }
  }

  // ============================================================
  // ADD PET
  // ============================================================

  Future<void> _addAnotherPet() async {
    final result = await showDialog<Pet>(
      context: context,
      builder: (context) => const _AddPetDialog(),
    );

    if (result == null) return;

    try {
      final savedPet = await PetService.instance.addPet(result);

      if (!mounted) return;

      setState(() {
        _pets = [..._pets, savedPet];
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pet added successfully!')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add pet: $e')));
    }
  }

  // ============================================================
  // EDIT PET
  // ============================================================

  Future<void> _editPet(int index) async {
    final result = await showDialog<Pet>(
      context: context,
      builder: (_) => _EditPetDialog(pet: _pets[index]),
    );

    if (result == null) return;

    try {
      final updatedPet = await PetService.instance.updatePet(result);

      if (!mounted) return;

      setState(() {
        _pets = List.of(_pets)..[index] = updatedPet;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update pet: $e')));
    }
  }

  // ============================================================
  // DELETE PET
  // ============================================================

  Future<void> _deletePet(int index) async {
    final pet = _pets[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(
              'Delete Pet',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            content: Text('Remove ${pet.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await PetService.instance.deletePet(pet.id);

      if (!mounted) return;

      setState(() {
        _pets = List.of(_pets)..removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet deleted successfully!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete pet: $e')));
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

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
                                  itemBuilder: (context, i) {
                                    final pet = _pets[i];
                                    return _PetCard(
                                      key: ValueKey(
                                        pet.id.isNotEmpty
                                            ? pet.id
                                            : pet.hashCode,
                                      ),
                                      pet: pet,
                                      onEdit: () => _editPet(i),
                                      onDelete: () => _deletePet(i),
                                    );
                                  },
                                ),
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: '+ Add  Pet',
                        onPressed: _addAnotherPet,
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}

// =================================================================
// PET CARD
// =================================================================

class _PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _PetCard({
    super.key,
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
              // --------------------------------------------------
              // PET PHOTO
              // --------------------------------------------------
              _PetImage(pet: pet, height: 50, width: 50, borderRadius: 8),

              const SizedBox(width: 12),

              // --------------------------------------------------
              // PET INFORMATION
              // --------------------------------------------------
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

              // --------------------------------------------------
              // EDIT
              // --------------------------------------------------
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),

              // --------------------------------------------------
              // DELETE
              // --------------------------------------------------
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

          // ------------------------------------------------------
          // DESCRIPTION
          // ------------------------------------------------------
          if (pet.description != null && pet.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(pet.description!, style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

// =================================================================
// PET IMAGE
// =================================================================

class _PetImage extends StatelessWidget {
  final Pet pet;
  final double height;
  final double width;
  final double borderRadius;

  const _PetImage({
    required this.pet,
    required this.height,
    required this.width,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(height: height, width: width, child: _buildImage()),
    );
  }

  Widget _buildImage() {
    // Local image selected from gallery.
    if (pet.imageFile != null) {
      return Image.file(pet.imageFile!, fit: BoxFit.cover);
    }

    // Image already stored in Supabase.
    if (pet.photoUrl != null && pet.photoUrl!.isNotEmpty) {
      return Image.network(
        pet.photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            color: AppColors.divider,
            child: const Icon(Icons.pets),
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }

          return Container(
            color: AppColors.divider,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    // No image.
    return Container(color: AppColors.divider, child: const Icon(Icons.pets));
  }
}

// =================================================================
// ADD PET DIALOG
// =================================================================

class _AddPetDialog extends StatefulWidget {
  const _AddPetDialog();

  @override
  State<_AddPetDialog> createState() => _AddPetDialogState();
}

class _AddPetDialogState extends State<_AddPetDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ageController = TextEditingController();
  final _otherBreedController = TextEditingController();
  String? _errorMessage;

  File? _imageFile;

  String? _selectedBreed;
  String? _selectedSex;

  final List<String> _breeds = [
    'Domestic Shorthair',
    'Domestic Longhair',
    'Persian',
    'Siamese',
    'Maine Coon',
    'Ragdoll',
    'British Shorthair',
    'Golden Retriever',
    'Labrador Retriever',
    'German Shepherd',
    'Poodle',
    'Shih Tzu',
    'Pomeranian',
    'Beagle',
    'Bulldog',
    'Other',
  ];

  Widget _buildBreedOptions() {
    return Column(
      children:
          _breeds.map((breed) {
            return RadioListTile<String>(
              title: Text(breed),
              value: breed,
              groupValue: _selectedBreed,
              contentPadding: EdgeInsets.zero,
              dense: true,
              onChanged: (value) {
                if (!mounted) return;

                setState(() {
                  _selectedBreed = value;

                  if (value != 'Other') {
                    _otherBreedController.clear();
                  }
                });
              },
            );
          }).toList(),
    );
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  // ============================================================
  // ADD PET
  // ============================================================

  void _addPet() {
    setState(() => _errorMessage = null);
    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();

    // ----------------------------------------------------------
    // BASIC VALIDATION
    // ----------------------------------------------------------

    if (name.isEmpty) {
      _showError('Please enter your pet\'s name.');
      return;
    }

    if (_selectedBreed == null) {
      _showError('Please select a breed.');
      return;
    }

    // If Other is selected, make sure they entered a breed.
    if (_selectedBreed == 'Other' &&
        _otherBreedController.text.trim().isEmpty) {
      _showError('Please specify your pet\'s breed.');
      return;
    }

    if (_selectedSex == null) {
      _showError('Please select your pet\'s sex.');
      return;
    }

    // ----------------------------------------------------------
    // AGE VALIDATION
    // ----------------------------------------------------------

    if (ageText.isEmpty) {
      _showError('Please enter your pet\'s age.');
      return;
    }

    // Only allow whole numbers.
    final age = int.tryParse(ageText);

    if (age == null) {
      _showError('Age must be a whole number, such as 5 or 12.');
      return;
    }

    // Prevent negative age.
    if (age < 0) {
      _showError('Age cannot be negative.');
      return;
    }

    // ----------------------------------------------------------
    // BREED VALUE
    // ----------------------------------------------------------

    final breed =
        _selectedBreed == 'Other'
            ? _otherBreedController.text.trim()
            : _selectedBreed!;

    // ----------------------------------------------------------
    // RETURN PET
    // ----------------------------------------------------------

    Navigator.of(context).pop(
      Pet(
        id: '',
        ownerId: '',
        name: name,
        breed: breed,
        sex: _selectedSex!,
        age: age,
        imageFile: _imageFile,
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
      ),
    );
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Pet'),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // ----------------------------------------------------
            // PHOTO
            // ----------------------------------------------------
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: _LocalImagePreview(
                  imageFile: _imageFile,
                  height: 80,
                  width: 80,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------------
            // NAME
            // ----------------------------------------------------
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Pet name'),
            ),

            const SizedBox(height: 16),

            // ----------------------------------------------------
            // BREED
            // ----------------------------------------------------
            const Text('Breed', style: TextStyle(fontWeight: FontWeight.w700)),

            const SizedBox(height: 6),

            _buildBreedOptions(),

            // ----------------------------------------------------
            // OTHER BREED
            // ----------------------------------------------------
            if (_selectedBreed == 'Other') ...[
              const SizedBox(height: 4),

              TextField(
                controller: _otherBreedController,
                decoration: const InputDecoration(
                  labelText: 'Specify breed',
                  hintText: 'Enter your pet\'s breed',
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ----------------------------------------------------
            // SEX
            // ----------------------------------------------------
            const Text('Sex', style: TextStyle(fontWeight: FontWeight.w700)),

            const SizedBox(height: 6),

            RadioListTile<String>(
              title: const Text('Male'),
              value: 'Male',
              groupValue: _selectedSex,
              contentPadding: EdgeInsets.zero,
              dense: true,
              onChanged: (value) {
                setState(() {
                  _selectedSex = value;
                });
              },
            ),

            RadioListTile<String>(
              title: const Text('Female'),
              value: 'Female',
              groupValue: _selectedSex,
              contentPadding: EdgeInsets.zero,
              dense: true,
              onChanged: (value) {
                setState(() {
                  _selectedSex = value;
                });
              },
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------------
            // AGE
            // ----------------------------------------------------
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                hintText: 'Enter age in years',
                helperText: 'Age must be a whole number',
              ),
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------------
            // DESCRIPTION
            // ----------------------------------------------------
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

      // ----------------------------------------------------------
      // ACTIONS
      // ----------------------------------------------------------
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),

        ElevatedButton(onPressed: _addPet, child: const Text('Add')),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    _otherBreedController.dispose();

    super.dispose();
  }
}

// =================================================================
// EDIT PET DIALOG
// =================================================================

class _EditPetDialog extends StatefulWidget {
  final Pet pet;

  const _EditPetDialog({required this.pet});

  @override
  State<_EditPetDialog> createState() => _EditPetDialogState();
}

class _EditPetDialogState extends State<_EditPetDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _otherBreedController;
  String? _errorMessage;

  File? _imageFile;

  String? _selectedBreed;
  String? _selectedSex;

  final List<String> _breeds = [
    'Domestic Shorthair',
    'Domestic Longhair',
    'Persian',
    'Siamese',
    'Maine Coon',
    'Ragdoll',
    'British Shorthair',
    'Golden Retriever',
    'Labrador Retriever',
    'German Shepherd',
    'Poodle',
    'Shih Tzu',
    'Pomeranian',
    'Beagle',
    'Bulldog',
    'Other',
  ];

  Widget _buildBreedOptions() {
    return Column(
      children:
          _breeds.map((breed) {
            return RadioListTile<String>(
              title: Text(breed),
              value: breed,
              groupValue: _selectedBreed,
              contentPadding: EdgeInsets.zero,
              dense: true,
              onChanged: (value) {
                if (!mounted) return;

                setState(() {
                  _selectedBreed = value;

                  if (value != 'Other') {
                    _otherBreedController.clear();
                  }
                });
              },
            );
          }).toList(),
    );
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.pet.name);

    _ageController = TextEditingController(text: widget.pet.age.toString());

    _descriptionController = TextEditingController(
      text: widget.pet.description ?? '',
    );

    _otherBreedController = TextEditingController();

    _imageFile = widget.pet.imageFile;

    // ----------------------------------------------------------
    // EXISTING BREED
    // ----------------------------------------------------------

    if (_breeds.contains(widget.pet.breed)) {
      _selectedBreed = widget.pet.breed;
    } else {
      _selectedBreed = 'Other';
      _otherBreedController.text = widget.pet.breed;
    }

    // ----------------------------------------------------------
    // EXISTING SEX
    // ----------------------------------------------------------

    if (widget.pet.sex == 'Male' || widget.pet.sex == 'Female') {
      _selectedSex = widget.pet.sex;
    }
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  // ============================================================
  // SAVE PET
  // ============================================================

  void _savePet() {
    setState(() => _errorMessage = null);
    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();

    // ----------------------------------------------------------
    // BASIC VALIDATION
    // ----------------------------------------------------------

    if (name.isEmpty) {
      _showError('Please enter your pet\'s name.');
      return;
    }

    if (_selectedBreed == null) {
      _showError('Please select a breed.');
      return;
    }

    if (_selectedBreed == 'Other' &&
        _otherBreedController.text.trim().isEmpty) {
      _showError('Please specify your pet\'s breed.');
      return;
    }

    if (_selectedSex == null) {
      _showError('Please select your pet\'s sex.');
      return;
    }

    // ----------------------------------------------------------
    // AGE VALIDATION
    // ----------------------------------------------------------

    if (ageText.isEmpty) {
      _showError('Please enter your pet\'s age.');
      return;
    }

    final age = int.tryParse(ageText);

    if (age == null) {
      _showError('Age must be a whole number, such as 5 or 12.');
      return;
    }

    if (age < 0) {
      _showError('Age cannot be negative.');
      return;
    }

    // ----------------------------------------------------------
    // BREED
    // ----------------------------------------------------------

    final breed =
        _selectedBreed == 'Other'
            ? _otherBreedController.text.trim()
            : _selectedBreed!;

    // ----------------------------------------------------------
    // RETURN UPDATED PET
    // ----------------------------------------------------------

    Navigator.of(context).pop(
      Pet(
        id: widget.pet.id,
        ownerId: widget.pet.ownerId,
        name: name,
        breed: breed,
        sex: _selectedSex!,
        age: age,
        imageFile: _imageFile,

        // Keep existing image if no new image is selected.
        photoUrl: widget.pet.photoUrl,

        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
      ),
    );
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
  }

  // ============================================================
  // BUILD
  // ============================================================

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
             if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ----------------------------------------------------
            // PHOTO
            // ----------------------------------------------------
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: _EditPetImagePreview(
                  imageFile: _imageFile,
                  photoUrl: widget.pet.photoUrl,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ----------------------------------------------------
            // NAME
            // ----------------------------------------------------
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Pet name'),
            ),

            const SizedBox(height: 16),

            // ----------------------------------------------------
            // BREED
            // ----------------------------------------------------
            const Text('Breed', style: TextStyle(fontWeight: FontWeight.w700)),

            const SizedBox(height: 6),

            _buildBreedOptions(),

            // ----------------------------------------------------
            // OTHER BREED
            // ----------------------------------------------------
            if (_selectedBreed == 'Other') ...[
              const SizedBox(height: 4),

              TextField(
                controller: _otherBreedController,
                decoration: const InputDecoration(
                  labelText: 'Specify breed',
                  hintText: 'Enter your pet\'s breed',
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ----------------------------------------------------
            // SEX
            // ----------------------------------------------------
            const Text('Sex', style: TextStyle(fontWeight: FontWeight.w700)),

            const SizedBox(height: 6),

            RadioListTile<String>(
              title: const Text('Male'),
              value: 'Male',
              groupValue: _selectedSex,
              contentPadding: EdgeInsets.zero,
              dense: true,
              onChanged: (value) {
                setState(() {
                  _selectedSex = value;
                });
              },
            ),

            RadioListTile<String>(
              title: const Text('Female'),
              value: 'Female',
              groupValue: _selectedSex,
              contentPadding: EdgeInsets.zero,
              dense: true,
              onChanged: (value) {
                setState(() {
                  _selectedSex = value;
                });
              },
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------------
            // AGE
            // ----------------------------------------------------
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                hintText: 'Enter age in years',
                helperText: 'Age must be a whole number',
              ),
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------------
            // DESCRIPTION
            // ----------------------------------------------------
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

      // ----------------------------------------------------------
      // ACTIONS
      // ----------------------------------------------------------
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),

        ElevatedButton(onPressed: _savePet, child: const Text('Save')),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    _otherBreedController.dispose();

    super.dispose();
  }
}

// =================================================================
// LOCAL IMAGE PREVIEW
// =================================================================

class _LocalImagePreview extends StatelessWidget {
  final File? imageFile;
  final double height;
  final double width;

  const _LocalImagePreview({
    required this.imageFile,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: height,
        width: width,
        color: AppColors.divider,
        child:
            imageFile != null
                ? Image.file(imageFile!, fit: BoxFit.cover)
                : const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }
}

// =================================================================
// EDIT PET IMAGE PREVIEW
// =================================================================

class _EditPetImagePreview extends StatelessWidget {
  final File? imageFile;
  final String? photoUrl;

  const _EditPetImagePreview({required this.imageFile, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 80,
        width: 80,
        color: AppColors.divider,
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    // Newly selected local image.
    if (imageFile != null) {
      return Image.file(imageFile!, fit: BoxFit.cover);
    }

    // Existing Supabase image.
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const Icon(Icons.add_a_photo_outlined);
        },
      );
    }

    // No image.
    return const Icon(Icons.add_a_photo_outlined);
  }
}
