// lib/screens/contacts_screen.dart
import 'package:flutter/material.dart';
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
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() {
      _loading = true;
      _errorMsg = '';
    });
    try {
      final data = await supabase
          .from('contacts')
          .select('id, name, number')
          .order('id');
      setState(() => _contacts = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      setState(() => _errorMsg = e.toString());
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
        'user_id': userId,
      });
      await _fetchContacts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Contact saved!'),
          backgroundColor: AppColors.alertGreen,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Save error: ${e.toString()}'),
          backgroundColor: AppColors.alertRed,
        ));
      }
    }
  }

  Future<void> _editContact(int id, String name, String number) async {
    try {
      await supabase
          .from('contacts')
          .update({'name': name, 'number': number}).eq('id', id);
      await _fetchContacts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Edit error: ${e.toString()}'),
          backgroundColor: AppColors.alertRed,
        ));
      }
    }
  }

  Future<void> _deleteContact(int id) async {
    try {
      await supabase.from('contacts').delete().eq('id', id);
      await _fetchContacts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Delete error: ${e.toString()}'),
          backgroundColor: AppColors.alertRed,
        ));
      }
    }
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
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.cyan),
                  onPressed: _fetchContacts,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_errorMsg.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.alertRed),
                ),
                child: Text('Error: $_errorMsg',
                    style: const TextStyle(
                        color: AppColors.alertRed, fontSize: 12)),
              ),
            if (_loading)
              const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.cyan))
            else if (_contacts.isEmpty && _errorMsg.isEmpty)
              const Center(
                child: Text('No contacts yet. Tap + to add one.',
                    style:
                        TextStyle(color: AppColors.textSecondary)),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, i) =>
                      _contactCard(_contacts[i]),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                Text(contact['name'] ?? '',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                Text(contact['number'] ?? '',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.amber, size: 18),
            onPressed: () =>
                _showContactDialog(existing: contact),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete,
                color: AppColors.alertRed, size: 18),
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
        title: Text(
            existing == null ? 'Add Contact' : 'Edit Contact',
            style:
                const TextStyle(color: AppColors.textPrimary)),
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
                style:
                    TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: AppColors.background),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final number = numCtrl.text.trim();
              if (name.isEmpty || number.isEmpty) return;
              Navigator.pop(context);
              if (existing == null) {
                _addContact(name, number);
              } else {
                _editContact(existing['id'], name, number);
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
        hintStyle:
            const TextStyle(color: AppColors.textSecondary),
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
