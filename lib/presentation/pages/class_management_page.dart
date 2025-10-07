// lib/presentation/pages/class_management_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/class_master.dart';
import '../../services/master_data_service.dart';

class ClassManagementPage extends StatefulWidget {
  const ClassManagementPage({super.key});

  @override
  State<ClassManagementPage> createState() => _ClassManagementPageState();
}

class _ClassManagementPageState extends State<ClassManagementPage> {
  final MasterDataService _service = MasterDataService();
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _classOrderController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<ClassMaster> _classes = [];
  bool _loading = true;
  bool _isEditing = false;
  int? _editingClassId;
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
      _loadClasses();
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
    _classNameController.dispose();
    _classOrderController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    if (_schoolId == null) return;
    
    setState(() => _loading = true);
    try {
      final response = await _service.getAllClasses(_schoolId!);
      if (response['success'] == true) {
        setState(() {
          _classes = (response['data'] as List)
              .map((json) => ClassMaster.fromJson(json))
              .toList();
        });
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to load classes');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading classes: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final createdBy = prefs.getString('userName') ?? 'Admin';

      final classMaster = ClassMaster(
        classId: _isEditing ? _editingClassId : null,
        className: _classNameController.text.trim(),
        classOrder: int.parse(_classOrderController.text.trim()),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        schoolId: _schoolId,
        createdBy: createdBy,
      );

      Map<String, dynamic> response;
      if (_isEditing) {
        response = await _service.updateClass(_editingClassId!, classMaster);
      } else {
        response = await _service.createClass(classMaster);
      }

      if (response['success'] == true) {
        _showSuccessSnackBar(_isEditing ? 'Class updated successfully' : 'Class created successfully');
        _resetForm();
        _loadClasses();
      } else {
        _showErrorSnackBar(response['message'] ?? 'Operation failed');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  Future<void> _deleteClass(ClassMaster classMaster) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Are you sure you want to delete "${classMaster.className}"?'),
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
        final response = await _service.deleteClass(classMaster.classId!);
        if (response['success'] == true) {
          _showSuccessSnackBar('Class deleted successfully');
          _loadClasses();
        } else {
          _showErrorSnackBar(response['message'] ?? 'Failed to delete class');
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting class: $e');
      }
    }
  }

  Future<void> _toggleStatus(ClassMaster classMaster) async {
    try {
      final response = await _service.toggleClassStatus(classMaster.classId!);
      if (response['success'] == true) {
        _showSuccessSnackBar('Class status updated successfully');
        _loadClasses();
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating status: $e');
    }
  }

  void _editClass(ClassMaster classMaster) {
    setState(() {
      _isEditing = true;
      _editingClassId = classMaster.classId;
      _classNameController.text = classMaster.className;
      _classOrderController.text = classMaster.classOrder.toString();
      _descriptionController.text = classMaster.description ?? '';
    });
  }

  void _resetForm() {
    setState(() {
      _isEditing = false;
      _editingClassId = null;
      _classNameController.clear();
      _classOrderController.clear();
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
        title: const Text('Class Management'),
        actions: [
          IconButton(
            onPressed: _loadClasses,
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
                            _isEditing ? 'Edit Class' : 'Add New Class',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _classNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Class Name *',
                                    hintText: 'e.g., Nursery, KG, 1, 2',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Class name is required';
                                    }
                                    if (value.trim().length > 50) {
                                      return 'Class name cannot exceed 50 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _classOrderController,
                                  decoration: const InputDecoration(
                                    labelText: 'Order *',
                                    hintText: '1, 2, 3',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Order is required';
                                    }
                                    if (int.tryParse(value.trim()) == null) {
                                      return 'Enter valid number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description (Optional)',
                              hintText: 'Additional details about the class',
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: _submitForm,
                                child: Text(_isEditing ? 'Update Class' : 'Add Class'),
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
                  child: _classes.isEmpty
                      ? const Center(
                          child: Text(
                            'No classes found.\nAdd your first class above.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _classes.length,
                          itemBuilder: (context, index) {
                            final classMaster = _classes[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  classMaster.className,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: classMaster.isActive ? null : Colors.grey,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Order: ${classMaster.classOrder}'),
                                    if (classMaster.description != null)
                                      Text(classMaster.description!),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: classMaster.isActive
                                                ? Colors.green
                                                : Colors.red,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            classMaster.isActive ? 'Active' : 'Inactive',
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
                                        _editClass(classMaster);
                                        break;
                                      case 'toggle':
                                        _toggleStatus(classMaster);
                                        break;
                                      case 'delete':
                                        _deleteClass(classMaster);
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
                                          Icon(classMaster.isActive
                                              ? Icons.visibility_off
                                              : Icons.visibility),
                                          const SizedBox(width: 8),
                                          Text(classMaster.isActive
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
