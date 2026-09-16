import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../data/models/listing.dart';
import 'create_controller.dart';

class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController(text: '1');
  final _description = TextEditingController();
  String? _category;
  String _condition = Listing.conditions.first;

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _stock.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please choose a category')));
      return;
    }

    final listing = await ref
        .read(createControllerProvider.notifier)
        .submit(
          title: _title.text.trim(),
          category: _category!,
          price: double.parse(_price.text.trim()),
          description: _description.text.trim(),
          stock: int.parse(_stock.text.trim()),
          condition: _condition,
        );

    if (!mounted) return;

    if (listing == null) {
      final error = ref.read(createControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.message ?? 'Could not create listing')),
      );
      return;
    }

    // Replace so back from the new listing returns to the grid, not the form.
    context.pushReplacement(AppRoutes.listingPath(listing.id));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('"${listing.title}" listed')));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createControllerProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New listing')),
      body: Form(
        key: _formKey,
        // Show errors as the user corrects them, not on every keystroke
        // before they have finished typing.
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.pad),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Titleist Pro V1 golf balls',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Title is required';
                if (value.length < 3) return 'Title is too short';
                if (value.length > 80) {
                  return 'Title must be under 80 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.pad),
            categories.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Could not load categories'),
              data: (items) => DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: items
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'Category is required' : null,
              ),
            ),
            const SizedBox(height: AppTheme.pad),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Price is required';
                      final parsed = double.tryParse(value);
                      if (parsed == null) return 'Enter a valid number';
                      if (parsed <= 0) return 'Price must be above 0';
                      if (parsed > 100000) return 'Price looks too high';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.gap),
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final parsed = int.tryParse(v?.trim() ?? '');
                      if (parsed == null) return 'Enter a whole number';
                      if (parsed < 1) return 'Must be at least 1';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.pad),
            DropdownButtonFormField<String>(
              value: _condition,
              decoration: const InputDecoration(labelText: 'Condition'),
              items: Listing.conditions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _condition = v!),
              validator: (v) => v == null ? 'Condition is required' : null,
            ),
            const SizedBox(height: AppTheme.pad),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Description is required';
                if (value.length < 10) {
                  return 'Add a little more detail (at least 10 characters)';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.pad * 1.5),
            FilledButton(
              // Disabled while in flight, as required by the brief.
              onPressed: state.isSubmitting ? null : _submit,
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Post listing'),
            ),
            const SizedBox(height: AppTheme.pad),
            Text(
              'Note: the demo API simulates creation, so this listing exists '
              'only for this session.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
