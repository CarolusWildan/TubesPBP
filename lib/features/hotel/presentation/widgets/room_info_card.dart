import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/network/api_client.dart';
import '../../../../shared/utils/image_url_resolver.dart';

class RoomInfoCard extends StatelessWidget {
  final String hotelName;
  final String roomType;
  final double rating;
  final String imageUrl;

  const RoomInfoCard({
    super.key,
    required this.hotelName,
    required this.roomType,
    required this.rating,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = resolveImageUrl(imageUrl) ?? imageUrl;

    return SectionCard(
      child: Row(
        children: [
          // Gambar kamar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _ResolvedNetworkImage(
              imageUrl: resolvedImageUrl,
              width: 80,
              height: 80,
            ),
          ),
          const SizedBox(width: 12),
          // Info hotel
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotelName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  roomType,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$rating (Exceptional)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolvedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;

  const _ResolvedNetworkImage({
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  @override
  State<_ResolvedNetworkImage> createState() => _ResolvedNetworkImageState();
}

class _ResolvedNetworkImageState extends State<_ResolvedNetworkImage> {
  late Future<Uint8List?> _imageBytesFuture;

  @override
  void initState() {
    super.initState();
    _imageBytesFuture = _loadImageBytes();
  }

  @override
  void didUpdateWidget(covariant _ResolvedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageBytesFuture = _loadImageBytes();
    }
  }

  Future<Uint8List?> _loadImageBytes() async {
    final uri = Uri.tryParse(widget.imageUrl);
    if (uri == null || !uri.hasScheme) return null;

    try {
      final response = await http.get(uri, headers: ApiClient.imageHeaders);
      final contentType = response.headers['content-type'] ?? '';
      final isImage = contentType.startsWith('image/');

      if (response.statusCode >= 200 && response.statusCode < 300 && isImage) {
        return response.bodyBytes;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _imageBytesFuture,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null) {
          return Image.memory(
            bytes,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        }

        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey.shade200,
          child: snapshot.connectionState == ConnectionState.waiting
              ? Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey.shade400,
                    ),
                  ),
                )
              : const Icon(Icons.hotel, color: Colors.grey),
        );
      },
    );
  }
}
