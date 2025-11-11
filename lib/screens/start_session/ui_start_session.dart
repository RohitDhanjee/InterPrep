import 'dart:io' as io; // IMPORTANT: Alias dart:io
import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:prepvrse/services/file_picker_service.dart'; // Import helper functions

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:prepvrse/common/constants/styles.dart';
import 'package:prepvrse/common/resources/widgets/buttons/app_text_button.dart';

class StartSessionScreen extends ConsumerStatefulWidget {
  const StartSessionScreen({required this.isPresentation, super.key});
  final bool isPresentation;

  @override
  ConsumerState<StartSessionScreen> createState() => _StartSessionScreenState();
}

class _StartSessionScreenState extends ConsumerState<StartSessionScreen> {
  bool _isLoading = false;

  // State variables updated for platform compatibility
  io.File? _pickedFile;
  Uint8List? _pickedFileBytes;

  String? _fileName;
  String documentId = "";

  // --- MODIFIED: Uses platform check for upload ---
  // The old signature `Future<String> uploadPdfToFirebase(String fileName, File file)` is replaced.
  Future<String> uploadPdfToFirebase(String fileName,
      {io.File? file, Uint8List? bytes}) async {
    final reference = FirebaseStorage.instance.ref().child("files/$fileName");
    UploadTask uploadTask;

    if (kIsWeb) {
      if (bytes == null) {
        throw Exception('File bytes are missing for web upload.');
      }
      uploadTask = reference.putData(bytes); // Use putData for web
    } else {
      if (file == null) {
        throw Exception('File is missing for mobile/desktop upload.');
      }
      uploadTask = reference.putFile(file); // Use putFile for mobile/desktop
    }

    await uploadTask.whenComplete(() => {});
    final downloadLink = await reference.getDownloadURL();
    return downloadLink;
  }

  final _fireStoreRef = FirebaseFirestore.instance;

  // --- REPLACED: Calls platform-aware helper and sets state correctly ---
  void pickFile() async {
    final pickedFileData = await pickFileForPlatform(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'pptx'],
    );

    if (pickedFileData != null) {
      // Clear previous data
      _pickedFile = null;
      _pickedFileBytes = null;

      setState(() {
        _fileName = pickedFileData.name;
        // Assign data based on platform helpers
        _pickedFileBytes = pickedFileData.bytes;
        _pickedFile = getFileFromPath(pickedFileData.path);
      });
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        );
      },
    );
  }

  // --- MODIFIED: Passes correct arguments to upload function ---
  Future<void> uploadFile() async {
    // Check if we have file data (either File or Bytes) AND a file name
    if ((_pickedFile != null || _pickedFileBytes != null) &&
        _fileName != null) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Pass both file and bytes, one will be null depending on the platform
        final fileDownloadLink = await uploadPdfToFirebase(
          _fileName!,
          file: _pickedFile,
          bytes: _pickedFileBytes,
        );

        final docRef = await _fireStoreRef.collection("files").add({
          "name": _fileName,
          "url": fileDownloadLink,
        });

        documentId = docRef.id;

        final userId = FirebaseAuth.instance.currentUser?.uid;

        final sessionsDocRef =
            FirebaseFirestore.instance.collection('sessions').doc(userId);
        final snapshot = await sessionsDocRef.get();

        List<dynamic> sessions = List.from(snapshot.data()!['sessions']);
        sessions.last['filePath'] = fileDownloadLink;
        await sessionsDocRef.update({'sessions': sessions});

        if (widget.isPresentation) {
          Get.toNamed(
            '/generated_questions',
            arguments: {
              "id": documentId,
            },
          );
        } else {
          dynamic args = Get.arguments;
          Get.toNamed(
            '/generated_questions',
            arguments: {
              "id": documentId,
              "jd": args['jd'],
              "position": args['position'],
              "experience": args['experience'],
            },
          );
        }

        setState(() {
          _pickedFile = null;
          _pickedFileBytes = null; // Clear bytes state
          _fileName = null;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        showErrorDialog("Failed to upload file: $e");
      }
    } else {
      showErrorDialog("Please attach a file before uploading.");
    }
  }

  String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Styles.primaryColor,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  widget.isPresentation
                      ? Text(
                          "Upload your presentation",
                          style: Styles.displayXlBoldStyle,
                        )
                      : Text(
                          "Attach your resume",
                          style: Styles.displayLargeNormalStyle,
                        ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text("Allowed Formats: .pptx & .pdf"),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color.fromRGBO(250, 249, 246, 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: IconButton(
                              onPressed: pickFile,
                              icon: const Icon(Icons.upload_file_outlined),
                              iconSize: 40,
                            ),
                          ),
                          Text("Choose File from Device"),
                          if (_fileName != null) ...[
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    getFileExtension(_fileName!) == 'pdf'
                                        ? Icons.picture_as_pdf
                                        : Icons.slideshow,
                                    color: getFileExtension(_fileName!) == 'pdf'
                                        ? Colors.red
                                        : Colors.orange,
                                  ), // File Icon
                                  SizedBox(width: 8),
                                  Text(
                                    _fileName!,
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),
                                  ), // File name
                                ],
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _isLoading
              ? Positioned(
                  left: 10,
                  bottom: 10,
                  right: 10,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : Positioned(
                  left: 10,
                  bottom: 5,
                  right: 10,
                  child: AppTextButton(
                    text: "Upload",
                    onTap: uploadFile,
                    color: Styles.primaryColor,
                  ),
                )
        ],
      ),
    );
  }
}
