// lib/screens/contacts_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../utils/constants.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() => _loading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      final data = await supabase
    .from('contacts')
    .select()
    .order('id');
      setState(() => _contacts = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      _showError('Failed to load contacts');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addContact(String name, String number) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      await supabase.from('contacts').insert({
  'name': name,
  'number': number,
});
      await _fetchContacts();
    } catch (e) {
      _showError('Failed to add contact');
    }
  }

  Future<void> _editContact(int id, String name, String number) async {
    try {
      await supabase
          .from('contacts')
          .update({'name': name, 'number': number}).eq('id', id);
      await _fetchContacts();
    } catch (e) {
      _showError('Failed to update contact');
    }
  }

  Future<void> _deleteContact(int id) async {
    try {
      await supabase.from('contacts').delete().eq('id', id);
      await _fetchContacts();
    } catch (e) {
      _showError('Failed to delete contact');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.alertRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const WatchtowerAppBar(),
      endDrawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Contacts', style: AppTextStyles.heading),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showContactDialog(),
                  child: const Icon(Icons.add_circle,
                      color: AppColors.cyan, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.cyan))
                : _contacts.isEmpty
                    ? const Center(
                        child: Text('No contacts yet.',
                            style:
                                TextStyle(color: AppColors.textSecondary)))
                    : Expanded(
                        child: ListView.builder(
                          itemCount: _contacts.length,
                          itemBuilder: (context, i) {
                            final c = _contacts[i];
                            return _contactCard(c);
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _contactCard(Map<String, dynamic> contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardMid,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.cyanDark,
            radius: 20,
            child: Icon(Icons.person, color: AppColors.cyan, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact['name'],
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                Text(contact['number'],
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.amber, size: 18),
            onPressed: () => _showContactDialog(existing: contact),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon:
                const Icon(Icons.delete, color: AppColors.alertRed, size: 18),
            onPressed: () => _deleteContact(contact['id']),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showContactDialog({Map<String, dynamic>? existing}) {
    final nameCtrl =
        TextEditingController(text: existing?['name'] ?? '');
    final numCtrl =
        TextEditingController(text: existing?['number'] ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(existing == null ? 'Add Contact' : 'Edit Contact',
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField('Name', nameCtrl),
            const SizedBox(height: 10),
            _dialogField('Number', numCtrl,
                type: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: AppColors.background),
            onPressed: () {
              Navigator.pop(context);
              if (existing == null) {
                _addContact(nameCtrl.text, numCtrl.text);
              } else {
                _editContact(existing['id'], nameCtrl.text, numCtrl.text);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(String hint, TextEditingController ctrl,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.cardMid,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
