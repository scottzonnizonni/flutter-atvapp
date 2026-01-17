import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../models/content_model.dart';
import '../providers/content_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';

class ContentFormScreen extends StatefulWidget {
  final ContentModel? content; // null for create, non-null for edit

  const ContentFormScreen({super.key, this.content});

  @override
  State<ContentFormScreen> createState() => _ContentFormScreenState();
}

class _ContentFormScreenState extends State<ContentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  String? _selectedCategory;
  String? _imagePath;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  int _descriptionLength = 0;
  static const int _maxDescriptionLength = 500;

  bool get isEditing => widget.content != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _titleController.text = widget.content!.title;
      _descriptionController.text = widget.content!.description;
      _selectedCategory = widget.content!.category;
      _imagePath = widget.content!.imagePath;
      _descriptionLength = widget.content!.description.length;
      if (widget.content!.latitude != null) {
        _latitudeController.text = widget.content!.latitude.toString();
      }
      if (widget.content!.longitude != null) {
        _longitudeController.text = widget.content!.longitude.toString();
      }
    }

    _descriptionController.addListener(() {
      setState(() {
        _descriptionLength = _descriptionController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imagePath = null;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permissão de localização negada'),
                backgroundColor: Color(AppConstants.deleteRed),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permissão de localização negada permanentemente. Ative nas configurações.',
              ),
              backgroundColor: Color(AppConstants.deleteRed),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Localização obtida com sucesso!'),
            backgroundColor: Color(AppConstants.primaryGreen),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao obter localização: $e'),
            backgroundColor: const Color(AppConstants.deleteRed),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  String _generateQrCodeId() {
    final uuid = const Uuid();
    final shortId = uuid.v4().substring(0, 8).toUpperCase();

    String categoryCode = 'GEN';
    switch (_selectedCategory) {
      case 'INFRAESTRUTURAS':
        categoryCode = 'INF';
        break;
      case 'PRODUÇÃO':
        categoryCode = 'PRD';
        break;
      case 'HISTÓRIA':
        categoryCode = 'HIS';
        break;
      case 'MEIO AMBIENTE':
        categoryCode = 'AMB';
        break;
      case 'CULTURA':
        categoryCode = 'CUL';
        break;
    }

    return '${AppConstants.qrCodePrefix}.$categoryCode.$shortId';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final uuid = const Uuid();
    final now = DateTime.now();

    double? latitude;
    double? longitude;

    if (_latitudeController.text.isNotEmpty) {
      latitude = double.tryParse(_latitudeController.text);
    }
    if (_longitudeController.text.isNotEmpty) {
      longitude = double.tryParse(_longitudeController.text);
    }

    final content = ContentModel(
      id: isEditing ? widget.content!.id : uuid.v4(),
      qrCodeId: isEditing ? widget.content!.qrCodeId : _generateQrCodeId(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory!,
      imagePath: _imagePath,
      latitude: latitude,
      longitude: longitude,
      createdAt: isEditing ? widget.content!.createdAt : now,
      updatedAt: now,
    );

    final contentProvider = context.read<ContentProvider>();
    final success = isEditing
        ? await contentProvider.updateContent(content)
        : await contentProvider.createContent(content);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Conteúdo atualizado com sucesso'
                  : 'Conteúdo criado com sucesso',
            ),
            backgroundColor: const Color(AppConstants.primaryGreen),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Erro ao atualizar conteúdo'
                  : 'Erro ao criar conteúdo',
            ),
            backgroundColor: const Color(AppConstants.deleteRed),
          ),
        );
      }
    }
  }

  Color _getDescriptionCounterColor() {
    if (_descriptionLength > _maxDescriptionLength * 0.9) {
      return const Color(AppConstants.deleteRed);
    } else if (_descriptionLength > _maxDescriptionLength * 0.7) {
      return Colors.orange;
    }
    return const Color(AppConstants.textGray);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundBlack),
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Conteúdo' : 'Novo Conteúdo'),
        backgroundColor: const Color(AppConstants.primaryGreen),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              validator: Validators.validateTitle,
              decoration: InputDecoration(
                labelText: 'Título *',
                labelStyle: const TextStyle(
                  color: Color(AppConstants.textGray),
                ),
                prefixIcon: const Icon(
                  Icons.title,
                  color: Color(AppConstants.primaryGreen),
                ),
                filled: true,
                fillColor: const Color(AppConstants.cardDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(AppConstants.primaryGreen),
                    width: 2,
                  ),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              validator: Validators.validateCategory,
              decoration: InputDecoration(
                labelText: 'Categoria *',
                labelStyle: const TextStyle(
                  color: Color(AppConstants.textGray),
                ),
                prefixIcon: const Icon(
                  Icons.category,
                  color: Color(AppConstants.primaryGreen),
                ),
                filled: true,
                fillColor: const Color(AppConstants.cardDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(AppConstants.primaryGreen),
                    width: 2,
                  ),
                ),
              ),
              dropdownColor: const Color(AppConstants.cardDark),
              style: const TextStyle(color: Colors.white),
              items: AppConstants.categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Description field with counter
            TextFormField(
              controller: _descriptionController,
              validator: Validators.validateDescription,
              maxLines: 6,
              maxLength: _maxDescriptionLength,
              decoration: InputDecoration(
                labelText: 'Descrição *',
                labelStyle: const TextStyle(
                  color: Color(AppConstants.textGray),
                ),
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 100),
                  child: Icon(
                    Icons.description,
                    color: Color(AppConstants.primaryGreen),
                  ),
                ),
                filled: true,
                fillColor: const Color(AppConstants.cardDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(AppConstants.primaryGreen),
                    width: 2,
                  ),
                ),
                counterText: '',
              ),
              style: const TextStyle(color: Colors.white),
            ),
            // Custom character counter
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.text_fields,
                    size: 14,
                    color: _getDescriptionCounterColor(),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_descriptionLength/$_maxDescriptionLength caracteres',
                    style: TextStyle(
                      color: _getDescriptionCounterColor(),
                      fontSize: 12,
                      fontWeight:
                          _descriptionLength > _maxDescriptionLength * 0.9
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Image picker with preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(AppConstants.cardDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _imagePath != null
                      ? const Color(
                          AppConstants.primaryGreen,
                        ).withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.image,
                        color: Color(AppConstants.primaryGreen),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Imagem (opcional)',
                        style: TextStyle(
                          color: Color(AppConstants.textGray),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Image preview or placeholder
                  if (_imagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Image.file(
                            File(_imagePath!),
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 200,
                                color: const Color(AppConstants.cardMedium),
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Color(AppConstants.textGray),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: _removeImage,
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(
                                  AppConstants.deleteRed,
                                ),
                                foregroundColor: Colors.white,
                              ),
                              tooltip: 'Remover imagem',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(AppConstants.cardMedium),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(
                            AppConstants.textGray,
                          ).withValues(alpha: 0.2),
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 48,
                            color: const Color(
                              AppConstants.textGray,
                            ).withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nenhuma imagem selecionada',
                            style: TextStyle(
                              color: const Color(
                                AppConstants.textGray,
                              ).withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(
                        _imagePath != null
                            ? Icons.edit
                            : Icons.add_photo_alternate,
                      ),
                      label: Text(
                        _imagePath != null
                            ? 'Alterar Imagem'
                            : 'Selecionar Imagem',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(AppConstants.primaryGreen),
                        side: const BorderSide(
                          color: Color(AppConstants.primaryGreen),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Location section with GPS button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(AppConstants.cardDark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(AppConstants.primaryGreen),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Localização (opcional)',
                            style: TextStyle(
                              color: Color(AppConstants.textGray),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      // GPS Button
                      OutlinedButton.icon(
                        onPressed: _isLoadingLocation
                            ? null
                            : _getCurrentLocation,
                        icon: _isLoadingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(AppConstants.primaryGreen),
                                ),
                              )
                            : const Icon(Icons.my_location, size: 18),
                        label: const Text('GPS'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(
                            AppConstants.primaryGreen,
                          ),
                          side: const BorderSide(
                            color: Color(AppConstants.primaryGreen),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latitudeController,
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            labelStyle: TextStyle(
                              color: Color(AppConstants.textGray),
                            ),
                            filled: true,
                            fillColor: Color(AppConstants.cardMedium),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _longitudeController,
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            labelStyle: TextStyle(
                              color: Color(AppConstants.textGray),
                            ),
                            filled: true,
                            fillColor: Color(AppConstants.cardMedium),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            CustomButton(
              text: isEditing ? 'Salvar Alterações' : 'Criar Conteúdo',
              onPressed: _handleSave,
              isLoading: _isLoading,
              icon: isEditing ? Icons.save : Icons.add,
            ),
          ],
        ),
      ),
    );
  }
}
