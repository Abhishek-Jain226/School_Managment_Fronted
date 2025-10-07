// lib/presentation/pages/section_management_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/section_master.dart';
import '../../services/master_data_service.dart';

class SectionManagementPage extends StatefulWidget {
  const SectionManagementPage({super.key});

  @override
  State<SectionManagementPage> createState() => _SectionManagementPageState();
}

class _SectionManagementPageState extends State<SectionManagementPage> {
  final MasterDataService _service = MasterDataService();
  final _formKey = GlobalKey<FormState>();
  final _sectionNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<SectionMaster> _sections = [];
  bool _loading = true;
  bool _isEditing = false;
  int? _editingSectionId;
  int? _schoolId;

  @override
  void initState() {
    super.initState();
    _loadSchoolId();
  }

  Future<void> _loadSchoolId() async {
    final prefs = await SharedPreferences.getInstance();
    _schoolId = prefs.getInt('schoolId');
    if (_schoolId != null) {
      _loadSections();
    } else {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School ID not found. Please login again.')),
      );
    }
  }

  @override
  void dispose() {
    _sectionNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSections() async {
    if (_schoolId == null) return;
    
    setState(() => _loading = true);
    try {
      final response = await _service.getAllSections(_schoolId!);
      if (response['success'] == true) {
        setState(() {
          _sections = (response['data'] as List)
              .map((json) => SectionMaster.fromJson(json))
              .toList();
        });
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to load sections');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading sections: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final createdBy = prefs.getString('userName') ?? 'Admin';

      final sectionMaster = SectionMaster(
        sectionId: _isEditing ? _editingSectionId : null,
        sectionName: _sectionNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        schoolId: _schoolId,
        createdBy: createdBy,
      );

      Map<String, dynamic> response;
      if (_isEditing) {
        response = await _service.updateSection(_editingSectionId!, sectionMaster);
      } else {
        response = await _service.createSection(sectionMaster);
      }

      if (response['success'] == true) {
        _showSuccessSnackBar(_isEditing ? 'Section updated successfully' : 'Section created successfully');
        _resetForm();
        _loadSections();
      } else {
        _showErrorSnackBar(response['message'] ?? 'Operation failed');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  Future<void> _deleteSection(SectionMaster sectionMaster) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section'),
        content: Text('Are you sure you want to delete "${sectionMaster.sectionName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _service.deleteSection(sectionMaster.sectionId!);
        if (response['success'] == true) {
          _showSuccessSnackBar('Section deleted successfully');
          _loadSections();
        } else {
          _showErrorSnackBar(response['message'] ?? 'Failed to delete section');
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting section: $e');
      }
    }
  }

  Future<void> _toggleStatus(SectionMaster sectionMaster) async {
    try {
      final response = await _service.toggleSectionStatus(sectionMaster.sectionId!);
      if (response['success'] == true) {
        _showSuccessSnackBar('Section status updated successfully');
        _loadSections();
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating status: $e');
    }
  }

  void _editSection(SectionMaster sectionMaster) {
    setState(() {
      _isEditing = true;
      _editingSectionId = sectionMaster.sectionId;
      _sectionNameController.text = sectionMaster.sectionName;
      _descriptionController.text = sectionMaster.description ?? '';
    });
  }

  void _resetForm() {
    setState(() {
      _isEditing = false;
      _editingSectionId = null;
      _sectionNameController.clear();
      _descriptionController.clear();
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Section Management'),
        actions: [
          IconButton(
            onPressed: _loadSections,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Form Section
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Edit Section' : 'Add New Section',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _sectionNameController,
                            decoration: const InputDecoration(
                              labelText: 'Section Name *',
                              hintText: 'e.g., A, B, Rose, Lily, Red, Blue',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Section name is required';
                              }
                              if (value.trim().length > 50) {
                                return 'Section name cannot exceed 50 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description (Optional)',
                              hintText: 'Additional details about the section',
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: _submitForm,
                                child: Text(_isEditing ? 'Update Section' : 'Add Section'),
                              ),
                              const SizedBox(width: 16),
                              if (_isEditing)
                                TextButton(
                                  onPressed: _resetForm,
                                  child: const Text('Cancel'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // List Section
                Expanded(
                  child: _sections.isEmpty
                      ? const Center(
                          child: Text(
                            'No sections found.\nAdd your first section above.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _sections.length,
                          itemBuilder: (context, index) {
                            final sectionMaster = _sections[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  sectionMaster.sectionName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: sectionMaster.isActive ? null : Colors.grey,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (sectionMaster.description != null)
                                      Text(sectionMaster.description!),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: sectionMaster.isActive
                                                ? Colors.green
                                                : Colors.red,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            sectionMaster.isActive ? 'Active' : 'Inactive',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _editSection(sectionMaster);
                                        break;
                                      case 'toggle':
                                        _toggleStatus(sectionMaster);
                                        break;
                                      case 'delete':
                                        _deleteSection(sectionMaster);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Row(
                                        children: [
                                          Icon(sectionMaster.isActive
                                              ? Icons.visibility_off
                                              : Icons.visibility),
                                          const SizedBox(width: 8),
                                          Text(sectionMaster.isActive
                                              ? 'Deactivate'
                                              : 'Activate'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
