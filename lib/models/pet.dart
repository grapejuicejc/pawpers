/// Represents a pet added under "My Pets" on the profile screen.
class Pet {
  final String id;
  final String ownerId;
  final String name;
  final String breed;
  final String? description;
  final String? photoUrl;

  Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.breed,
    this.description,
    this.photoUrl,
  });

  // ---------------------------------------------------------------------
  // DB (Supabase) — maps to a future `pets` table: id, owner_id, name,
  // breed, description, photo_url, created_at.
  // ---------------------------------------------------------------------
  // factory Pet.fromMap(Map<String, dynamic> map) {
  //   return Pet(
  //     id: map['id'] as String,
  //     ownerId: map['owner_id'] as String,
  //     name: map['name'] as String,
  //     breed: map['breed'] as String,
  //     description: map['description'] as String?,
  //     photoUrl: map['photo_url'] as String?,
  //   );
  // }
  //
  // Map<String, dynamic> toMap() {
  //   return {
  //     'owner_id': ownerId,
  //     'name': name,
  //     'breed': breed,
  //     'description': description,
  //     'photo_url': photoUrl,
  //   };
  // }
}