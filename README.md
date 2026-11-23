# PawPers

### Improving Access to Veterinary Support for Cats and Dogs Through a Community-Driven Mobile Platform with AI-Assisted Emotion Recognition

PawPers is an Android mobile application developed as my Final Year Project (FYP). It aims to improve access to veterinary support for cat and dog owners in Malaysia by providing a platform where pet owners and animal lovers can connect, share information and access useful veterinary resources.

The application also incorporates AI-assisted emotion recognition to help users explore their pets' possible emotional states through image classification.

## Download the Application

**[Download PawPers APK](YOUR_GITHUB_RELEASE_LINK_HERE)**

- Platform: Android
- Version: 1.0.0
- File format: APK

*Note: PawPers is an academic project. AI emotion recognition provides an indicative result for informational purposes only and is not intended to diagnose medical conditions or replace professional veterinary advice.*

## Key Features

### 1. Community Platform
- Create and share posts with other pet owners.
- Upload images and participate in discussions.
- React to posts and interact through comments and replies.
- Explore discussions related to cats and dogs.

### 2. AI-Assisted Pet Emotion Recognition
- Upload an image of a cat or dog for emotion classification.
- View the predicted emotion and confidence score.
- Receive relevant information and resources based on the prediction.
- Submit feedback when recognition results are incorrect or unhelpful.

### 3. Stray Animal Reporting
- Report stray cats and dogs within the community.
- Upload images of reported animals.
- Select the animal's location using Google Maps.
- View reported stray animal information.

### 4. Veterinary Clinic Discovery
- Discover nearby veterinary clinics.
- View clinic information and location details.
- Access clinic details through Google Places integration.

### 5. Veterinary Verification
- Veterinary professionals can submit verification details.
- Upload supporting documents for verification.
- Administrators can review and approve verification requests.

### 6. User Profiles
- Create and manage user profiles.
- Upload profile pictures and update personal information.
- View other community members' profiles.

## 🛠️ Technologies Used

| Category | Technologies |
|---|---|
| Mobile Development | Flutter, Dart |
| Backend & Database | Supabase |
| Authentication | Supabase Auth |
| File Storage | Supabase Storage |
| AI / Machine Learning | Python, TensorFlow, ResNet50V2, TensorFlow Lite |
| AI Backend | FastAPI |
| Maps & Location | Google Maps API, Google Places API |
| Development Tools | Visual Studio Code, Android Studio, Git, GitHub |

##  AI Emotion Recognition

PawPers uses deep learning models to classify the emotional expressions of cats and dogs from uploaded images.

The application uses separate ResNet50V2 models trained for cat and dog emotion classification.

**Supported emotion categories:**

- **Cats:** Aggressive, Sad, Happy, Relaxed
- **Dogs:** Angry, Sad, Happy, Relaxed

The models generate a predicted emotion along with a confidence score. These results are intended to provide an informative and engaging experience rather than a veterinary diagnosis.

## User Interface

<img width="1080" height="2412" alt="WhatsApp Image 2026-08-31 at 22 29 25" src="https://github.com/user-attachments/assets/c731150d-cb64-41b7-a8cf-b378cc837bad" />
