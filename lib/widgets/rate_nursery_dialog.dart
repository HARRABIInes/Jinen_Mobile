import 'package:flutter/material.dart';
import '../services/review_service_web.dart';
import '../models/nursery.dart';

class RateNurseryDialog extends StatefulWidget {
  final Nursery nursery;
  final String parentId;
  final VoidCallback? onReviewSubmitted;

  const RateNurseryDialog({
    super.key,
    required this.nursery,
    required this.parentId,
    this.onReviewSubmitted,
  });

  @override
  State<RateNurseryDialog> createState() => _RateNurseryDialogState();
}

class _RateNurseryDialogState extends State<RateNurseryDialog> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  Map<String, dynamic>? _existingReview;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingReview();
  }

  Future<void> _loadExistingReview() async {
    final review = await ReviewService.getParentReview(
      widget.parentId,
      widget.nursery.id,
    );

    setState(() {
      _existingReview = review;
      if (review != null) {
        final ratingValue = review['rating'] ?? 0;
        _rating = ratingValue is double ? ratingValue : double.tryParse(ratingValue.toString()) ?? 0.0;
        _commentController.text = review['comment'] ?? '';
      }
      _isLoading = false;
    });
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une note')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ReviewService.submitReview(
      nurseryId: widget.nursery.id,
      parentId: widget.parentId,
      rating: _rating,
      comment: _commentController.text.isEmpty ? null : _commentController.text,
    );

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avis soumis avec succès! ✅')),
        );
        widget.onReviewSubmitted?.call();
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result['error']}')),
        );
      }
    }
  }

  Future<void> _deleteReview() async {
    if (_existingReview == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'avis?'),
        content: const Text('Êtes-vous sûr de vouloir supprimer votre avis?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSubmitting = true);

      final result = await ReviewService.deleteReview(_existingReview!['id']);

      setState(() => _isSubmitting = false);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review deleted successfully!')),
          );
          widget.onReviewSubmitted?.call();
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result['error']}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Noter cette garderie',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.nursery.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Star rating
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Votre note',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starValue = index + 1;
                            return GestureDetector(
                              onTap: () => setState(() => _rating = starValue.toDouble()),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(
                                  _rating >= starValue
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 40,
                                  color: Colors.amber,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _rating > 0
                                ? '${_rating.toStringAsFixed(1)} / 5.0'
                                : 'Sélectionnez une note',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _rating > 0
                                  ? const Color(0xFF6366F1)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Comment field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Votre commentaire (Optionnel)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _commentController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Partagez votre expérience avec cette garderie...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF6366F1),
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        if (_existingReview != null)
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: _isSubmitting ? null : _deleteReview,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text('Supprimer'),
                            ),
                          ),
                        if (_existingReview != null) const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _isSubmitting ? null : _submitReview,
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(_existingReview != null ? 'Mettre à jour' : 'Soumettre'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
