import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'settings_provider.dart';
import 'profile_avatar.dart';
import 'guest_registration_dialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  late String _tempFrame;
  String? _newImagePath;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> _availableFrames = [
    {'id': 'none', 'label': 'None'},
    {'id': 'gold', 'label': 'Gold'},
    {'id': 'neon', 'label': 'Neon'},
    {'id': 'minimal', 'label': 'Minimal'},
  ];

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _nameController.text = settings.userName;
    _tempFrame = settings.profileFrame;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile', // Hardcoded as fallback or could be added to localization
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ProfileAvatar(
                    imageUrl: _newImagePath ?? settings.profilePicture,
                    frame: _tempFrame,
                    radius: 60,
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (settings.isGuestUser) {
                        showGuestRegistrationDialog(context, featureName: 'profile picture changes');
                        return;
                      }
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        final croppedFile = await ImageCropper().cropImage(
                          sourcePath: image.path,
                          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
                          uiSettings: [
                            AndroidUiSettings(
                                toolbarTitle: 'Adjust Profile Picture',
                                toolbarColor: const Color(0xFF5442F5),
                                toolbarWidgetColor: Colors.white,
                                initAspectRatio: CropAspectRatioPreset.square,
                                lockAspectRatio: true),
                            IOSUiSettings(
                              title: 'Adjust Profile Picture',
                              aspectRatioLockEnabled: true,
                              resetButtonHidden: true,
                            ),
                          ],
                        );

                        if (croppedFile != null) {
                          setState(() {
                            _newImagePath = croppedFile.path;
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF5442F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              enabled: !settings.isGuestUser,
              onTap: () {
                if (settings.isGuestUser) {
                  showGuestRegistrationDialog(context, featureName: 'name changes');
                }
              },
              decoration: InputDecoration(
                hintText: 'Enter your name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Profile Frame',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _availableFrames.length,
                itemBuilder: (context, index) {
                  final frame = _availableFrames[index];
                  final isSelected = _tempFrame == frame['id'];
                  return GestureDetector(
                    onTap: () {
                      if (settings.isGuestUser) {
                        showGuestRegistrationDialog(context, featureName: 'frame changes');
                        return;
                      }
                      setState(() {
                        _tempFrame = frame['id']!;
                      });
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF5442F5).withValues(alpha: 0.1)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF5442F5)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ProfileAvatar(
                            imageUrl:
                                _newImagePath ??
                                settings.profilePicture, // Use current pic
                            frame: frame['id']!,
                            radius: 25,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            frame['label']!,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5442F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final settings = Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  );
                  if (_nameController.text.trim().isNotEmpty) {
                    settings.updateUserName(_nameController.text.trim());
                  }
                  if (_newImagePath != null) {
                    settings.updateProfilePicture(_newImagePath!);
                  }
                  settings.updateProfileFrame(_tempFrame);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
