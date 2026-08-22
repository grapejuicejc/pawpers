import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet.dart';

class PetService {
  PetService._();

  static final PetService instance = PetService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// Gets the currently logged-in user's Auth ID.
  String get _currentUserId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('No user is currently logged in.');
    }

    return user.id;
  }

  /// Fetch all pets belonging to the current user.
  Future<List<Pet>> fetchMyPets() async {
    final userId = _currentUserId;

    final response = await _client
        .from('Pets')
        .select()
        .eq('userID', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Pet.fromJson(json)).toList();
  }

  /// Add a new pet.
  // Future<Pet> addPet(Pet pet) async {
  //   final userId = _currentUserId;

  //   String? photoUrl;

  //   // Upload photo if one was selected.
  //   if (pet.imageFile != null) {
  //     photoUrl = await _uploadPetPhoto(
  //       pet.imageFile!,
  //       userId,
  //       pet.id,
  //     );
  //   }

  //   final data = {
  //     'id': pet.id,
  //     'userID': userId,
  //     'petName': pet.name,
  //     'petAge': pet.age,
  //     'petBreed': pet.breed,
  //     'petSex': pet.sex,
  //     'petPhotoUrl': photoUrl,
  //     'petDescription': pet.description,
  //   };

  //   final response =
  //       await _client.from('Pets').insert(data).select().single();

  //   return Pet.fromJson(response);
  // }

  Future<Pet> addPet(Pet pet) async {
    final userId = _currentUserId;

    print('USER ID: $userId');
    print('PET NAME: ${pet.name}');
    print('PET AGE: ${pet.age}');
    print('PET BREED: ${pet.breed}');
    print('PET SEX: ${pet.sex}');

    final response =
        await _client
            .from('Pets')
            .insert({
              'userID': userId,
              'petName': pet.name,
              'petAge': pet.age,
              'petBreed': pet.breed,
              'petSex': pet.sex,
              'petDescription': pet.description,
            })
            .select()
            .single();

    var savedPet = Pet.fromJson(Map<String, dynamic>.from(response));

    if (pet.imageFile != null) {
      final photoUrl = await _uploadPetPhoto(
        pet.imageFile!,
        userId,
        savedPet.id,
      );

      final updatedResponse =
          await _client
              .from('Pets')
              .update({'petPhotoUrl': photoUrl})
              .eq('id', savedPet.id)
              .eq('userID', userId)
              .select()
              .single();

      savedPet = Pet.fromJson(Map<String, dynamic>.from(updatedResponse));
    }

    return savedPet;
  }

  /// Update an existing pet.
  Future<Pet> updatePet(Pet pet) async {
    final userId = _currentUserId;

    String? photoUrl = pet.photoUrl;

    // Upload a new photo only if the user selected one.
    if (pet.imageFile != null) {
      photoUrl = await _uploadPetPhoto(pet.imageFile!, userId, pet.id);
    }

    final data = {
      'petName': pet.name,
      'petAge': pet.age,
      'petBreed': pet.breed,
      'petSex': pet.sex,
      'petPhotoUrl': photoUrl,
      'petDescription': pet.description,
    };

    final response =
        await _client
            .from('Pets')
            .update(data)
            .eq('id', pet.id)
            .eq('userID', userId)
            .select()
            .single();

    return Pet.fromJson(response);
  }

  /// Delete a pet.
  Future<void> deletePet(String petId) async {
    final userId = _currentUserId;

    final petResponse =
        await _client
            .from('Pets')
            .select('petPhotoUrl')
            .eq('id', petId)
            .eq('userID', userId)
            .maybeSingle();

    if (petResponse == null) {
      throw Exception('Pet not found.');
    }

    final photoUrl = petResponse['petPhotoUrl'];

    // 2. Delete the photo from Storage
    if (photoUrl != null && photoUrl.toString().isNotEmpty) {
      try {
        final url = photoUrl.toString();

        // Example URL:
        // https://xxxxx.supabase.co/storage/v1/object/public/
        // pet-profiles/userID/petID.jpg

        final marker = '/storage/v1/object/public/pet-profiles/';

        final index = url.indexOf(marker);

        if (index != -1) {
          final filePath = url.substring(index + marker.length);

          await _client.storage.from('pet-profiles').remove([filePath]);
        }
      } catch (e) {
        debugPrint('Failed to delete pet photo: $e');
      }
    }

    await _client.from('Pets').delete().eq('id', petId).eq('userID', userId);
  }

  /// Upload pet photo to the `pet-profiles` bucket.
  Future<String> _uploadPetPhoto(
    File imageFile,
    String userId,
    String petId,
  ) async {
    final extension = imageFile.path.split('.').last.toLowerCase();

    final filePath = '$userId/$petId.$extension';

    await _client.storage
        .from('pet-profiles')
        .upload(
          filePath,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );

    return _client.storage.from('pet-profiles').getPublicUrl(filePath);
  }
}
