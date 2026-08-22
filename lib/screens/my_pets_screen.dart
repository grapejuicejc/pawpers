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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load pets: $e',
          ),
        ),
      );
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
      final savedPet =
          await PetService.instance.addPet(result);

      if (!mounted) return;

      setState(() {
        _pets = [
          ..._pets,
          savedPet,
        ];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pet added successfully!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add pet: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // EDIT PET
  // ============================================================

  Future<void> _editPet(
    int index,
  ) async {
    final result = await showDialog<Pet>(
      context: context,
      builder: (_) => _EditPetDialog(
        pet: _pets[index],
      ),
    );

    if (result == null) return;

    try {
      final updatedPet =
          await PetService.instance.updatePet(result);

      if (!mounted) return;

      setState(() {
        _pets = List.of(_pets)
          ..[index] = updatedPet;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pet updated successfully!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update pet: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // DELETE PET
  // ============================================================

  Future<void> _deletePet(
    int index,
  ) async {
    final pet = _pets[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Delete Pet',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Remove ${pet.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.danger,
            ),
            onPressed: () =>
                Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await PetService.instance.deletePet(
        pet.id,
      );

      if (!mounted) return;

      setState(() {
        _pets = List.of(_pets)
          ..removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pet deleted successfully!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete pet: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Pets',
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _pets.isEmpty
                          ? const Center(
                              child: Text(
                                'No pets added yet.',
                                style: TextStyle(
                                  color: AppColors
                                      .textSecondary,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount:
                                  _pets.length,
                              separatorBuilder:
                                  (_, __) =>
                                      const SizedBox(
                                height: 12,
                              ),
                              itemBuilder:
                                  (context, i) {
                                return _PetCard(
                                  pet: _pets[i],
                                  onEdit: () =>
                                      _editPet(i),
                                  onDelete: () =>
                                      _deletePet(i),
                                );
                              },
                            ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    PrimaryButton(
                      label:
                          '+ Add  Pet',
                      onPressed:
                          _addAnotherPet,
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
    required this.pet,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.divider,
        ),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // PET PHOTO
              // --------------------------------------------------

              _PetImage(
                pet: pet,
                height: 50,
                width: 50,
                borderRadius: 8,
              ),

              const SizedBox(
                width: 12,
              ),

              // --------------------------------------------------
              // PET INFORMATION
              // --------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    Text(
                      pet.breed,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color: AppColors
                            .textSecondary,
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
                  color:
                      AppColors.primary,
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
                  color:
                      AppColors.danger,
                ),
              ),
            ],
          ),

          // ------------------------------------------------------
          // DESCRIPTION
          // ------------------------------------------------------

          if (pet.description != null &&
              pet.description!
                  .isNotEmpty) ...[
            const SizedBox(
              height: 8,
            ),
            Text(
              pet.description!,
              style:
                  const TextStyle(
                fontSize: 12,
              ),
            ),
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
      borderRadius:
          BorderRadius.circular(
        borderRadius,
      ),
      child: SizedBox(
        height: height,
        width: width,
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    // Local image selected from gallery.
    if (pet.imageFile != null) {
      return Image.file(
        pet.imageFile!,
        fit: BoxFit.cover,
      );
    }

    // Image already stored in Supabase.
    if (pet.photoUrl != null &&
        pet.photoUrl!.isNotEmpty) {
      return Image.network(
        pet.photoUrl!,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) {
          return Container(
            color: AppColors.divider,
            child: const Icon(
              Icons.pets,
            ),
          );
        },
        loadingBuilder:
            (context, child, progress) {
          if (progress == null) {
            return child;
          }

          return Container(
            color: AppColors.divider,
            child: const Center(
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          );
        },
      );
    }

    // No image.
    return Container(
      color: AppColors.divider,
      child: const Icon(
        Icons.pets,
      ),
    );
  }
}

// =================================================================
// ADD PET DIALOG
// =================================================================

class _AddPetDialog
    extends StatefulWidget {
  const _AddPetDialog();

  @override
  State<_AddPetDialog> createState() =>
      _AddPetDialogState();
}

class _AddPetDialogState
    extends State<_AddPetDialog> {
  final _nameController =
      TextEditingController();

  final _breedController =
      TextEditingController();

  final _descriptionController =
      TextEditingController();

  final _sexController =
      TextEditingController();

  final _ageController =
      TextEditingController();

  File? _imageFile;

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _imageFile =
            File(picked.path);
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Add Pet',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            // ----------------------------------------------------
            // PHOTO
            // ----------------------------------------------------

            GestureDetector(
              onTap: _pickImage,
              child: _LocalImagePreview(
                imageFile: _imageFile,
                height: 80,
                width: 80,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // ----------------------------------------------------
            // NAME
            // ----------------------------------------------------

            TextField(
              controller:
                  _nameController,
              decoration:
                  const InputDecoration(
                hintText:
                    'Pet name',
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // ----------------------------------------------------
            // BREED
            // ----------------------------------------------------

            TextField(
              controller:
                  _breedController,
              decoration:
                  const InputDecoration(
                hintText:
                    'Breed',
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // ----------------------------------------------------
            // SEX
            // ----------------------------------------------------

            TextField(
              controller:
                  _sexController,
              decoration:
                  const InputDecoration(
                hintText:
                    'Sex (e.g. Male / Female)',
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // ----------------------------------------------------
            // AGE
            // ----------------------------------------------------

            TextField(
              controller:
                  _ageController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                hintText:
                    'Age',
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // ----------------------------------------------------
            // DESCRIPTION
            // ----------------------------------------------------

            TextField(
              controller:
                  _descriptionController,
              decoration:
                  const InputDecoration(
                hintText:
                    'Description (optional)',
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
          onPressed: () =>
              Navigator.of(
                context,
              ).pop(),
          child: const Text(
            'Cancel',
          ),
        ),

        ElevatedButton(
          onPressed: _addPet,
          child: const Text(
            'Add',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ADD PET
  // ============================================================

  void _addPet() {
    if (_nameController.text
            .trim()
            .isEmpty ||
        _breedController.text
            .trim()
            .isEmpty ||
        _sexController.text
            .trim()
            .isEmpty ||
        _ageController.text
            .trim()
            .isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      Pet(
        // PetService generates the UUID.
        id: '',
        ownerId: '',
        name:
            _nameController.text.trim(),
        breed:
            _breedController.text.trim(),
        sex:
            _sexController.text.trim(),
        age:
            int.tryParse(
              _ageController.text
                  .trim(),
            ) ??
            0,
        imageFile:
            _imageFile,
        description:
            _descriptionController
                    .text
                    .trim()
                    .isEmpty
                ? null
                : _descriptionController
                    .text
                    .trim(),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _sexController.dispose();
    _ageController.dispose();
    _descriptionController
        .dispose();

    super.dispose();
  }
}

// =================================================================
// EDIT PET DIALOG
// =================================================================

class _EditPetDialog
    extends StatefulWidget {
  final Pet pet;

  const _EditPetDialog({
    required this.pet,
  });

  @override
  State<_EditPetDialog> createState() =>
      _EditPetDialogState();
}

class _EditPetDialogState
    extends State<_EditPetDialog> {
  late final TextEditingController
      _nameController;

  late final TextEditingController
      _breedController;

  late final TextEditingController
      _sexController;

  late final TextEditingController
      _ageController;

  late final TextEditingController
      _descriptionController;

  File? _imageFile;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(
      text: widget.pet.name,
    );

    _breedController =
        TextEditingController(
      text: widget.pet.breed,
    );

    _sexController =
        TextEditingController(
      text: widget.pet.sex,
    );

    _ageController =
        TextEditingController(
      text: widget.pet.age.toString(),
    );

    _descriptionController =
        TextEditingController(
      text:
          widget.pet.description ?? '',
    );

    _imageFile =
        widget.pet.imageFile;
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _imageFile =
            File(picked.path);
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Edit Pet',
        style:
            GoogleFonts.poppins(
          fontWeight:
              FontWeight.w700,
        ),
      ),

      content:
          SingleChildScrollView(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const SizedBox(
              height: 8,
            ),

            // ----------------------------------------------------
            // PHOTO
            // ----------------------------------------------------

            GestureDetector(
              onTap: _pickImage,
              child:
                  _EditPetImagePreview(
                imageFile:
                    _imageFile,
                photoUrl:
                    widget.pet.photoUrl,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ----------------------------------------------------
            // NAME
            // ----------------------------------------------------

            TextField(
              controller:
                  _nameController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Pet name',
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ----------------------------------------------------
            // BREED
            // ----------------------------------------------------

            TextField(
              controller:
                  _breedController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Breed',
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ----------------------------------------------------
            // SEX
            // ----------------------------------------------------

            TextField(
              controller:
                  _sexController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Sex (e.g. Male / Female)',
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ----------------------------------------------------
            // AGE
            // ----------------------------------------------------

            TextField(
              controller:
                  _ageController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText:
                    'Age',
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ----------------------------------------------------
            // DESCRIPTION
            // ----------------------------------------------------

            TextField(
              controller:
                  _descriptionController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Description (optional)',
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
          onPressed: () =>
              Navigator.of(
                context,
              ).pop(),
          child: const Text(
            'Cancel',
          ),
        ),

        ElevatedButton(
          onPressed: _savePet,
          child: const Text(
            'Save',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  void _savePet() {
    if (_nameController.text
            .trim()
            .isEmpty ||
        _breedController.text
            .trim()
            .isEmpty ||
        _sexController.text
            .trim()
            .isEmpty ||
        _ageController.text
            .trim()
            .isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      Pet(
        id: widget.pet.id,
        ownerId:
            widget.pet.ownerId,
        name:
            _nameController.text.trim(),
        breed:
            _breedController.text.trim(),
        sex:
            _sexController.text.trim(),
        age:
            int.tryParse(
              _ageController.text
                  .trim(),
            ) ??
            widget.pet.age,
        imageFile:
            _imageFile,

        // Keep the old Supabase
        // photo URL if the user
        // doesn't select a new image.
        photoUrl:
            widget.pet.photoUrl,

        description:
            _descriptionController
                    .text
                    .trim()
                    .isEmpty
                ? null
                : _descriptionController
                    .text
                    .trim(),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _sexController.dispose();
    _ageController.dispose();
    _descriptionController
        .dispose();

    super.dispose();
  }
}

// =================================================================
// LOCAL IMAGE PREVIEW
// =================================================================

class _LocalImagePreview
    extends StatelessWidget {
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
      borderRadius:
          BorderRadius.circular(8),
      child: Container(
        height: height,
        width: width,
        color: AppColors.divider,
        child: imageFile != null
            ? Image.file(
                imageFile!,
                fit: BoxFit.cover,
              )
            : const Icon(
                Icons
                    .add_a_photo_outlined,
              ),
      ),
    );
  }
}

// =================================================================
// EDIT PET IMAGE PREVIEW
// =================================================================

class _EditPetImagePreview
    extends StatelessWidget {
  final File? imageFile;
  final String? photoUrl;

  const _EditPetImagePreview({
    required this.imageFile,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(8),
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
      return Image.file(
        imageFile!,
        fit: BoxFit.cover,
      );
    }

    // Existing Supabase image.
    if (photoUrl != null &&
        photoUrl!.isNotEmpty) {
      return Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) {
          return const Icon(
            Icons
                .add_a_photo_outlined,
          );
        },
      );
    }

    // No image.
    return const Icon(
      Icons.add_a_photo_outlined,
    );
  }
}