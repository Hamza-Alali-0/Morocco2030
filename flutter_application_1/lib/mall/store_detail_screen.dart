import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/mall/store_model.dart';
import 'package:flutter_application_1/mall/store_service.dart';
import 'package:flutter_application_1/mall/mall_model.dart';
import 'package:cached_network_image/cached_network_image.dart';


class StoreDetailScreen extends StatefulWidget {
  final Mall mall;

  const StoreDetailScreen({Key? key, required this.mall}) : super(key: key);

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen>
    with SingleTickerProviderStateMixin {
  final StoreService _storeService = StoreService();
  bool _isLoading = true;
  List<Store> _stores = [];
  Map<String, List<Store>> _categorizedStores = {};
  String _debugMessage = '';

  // Filter state variables
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _priceRange = 'All';
  bool _onlyFeatured = false;

  // Animation
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;
  bool _showFilters = false;

  // 1) Track expanded/collapsed state per category
  Map<String, bool> _categoryExpansionState = {};

  // Main app color
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);

  @override
  void initState() {
    super.initState();
    _loadStores();

    _filterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _filterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _filterAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    super.dispose();
  }

  // Toggle filter visibility
  void _toggleFilterVisibility() {
    setState(() {
      _showFilters = !_showFilters;
      if (_showFilters) {
        _filterAnimationController.forward();
      } else {
        _filterAnimationController.reverse();
      }
    });
  }

  // Filter stores based on criteria
  List<Store> _getFilteredStores() {
    List<Store> filteredStores = List.from(_stores);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredStores =
          filteredStores
              .where(
                (store) =>
                    store.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    store.description.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      filteredStores =
          filteredStores
              .where((store) => store.category == _selectedCategory)
              .toList();
    }

    // Filter by price range
    if (_priceRange != 'All') {
      // Implement price range filtering logic if needed
    }

    // Filter featured stores
    if (_onlyFeatured) {
      filteredStores =
          filteredStores.where((store) => store.isFeatured).toList();
    }

    return filteredStores;
  }

  // Get all unique categories for filter dropdown
  List<String> _getCategories() {
    final Set<String> categories = {'All'};
    for (var store in _stores) {
      if (store.category.isNotEmpty) {
        categories.add(store.category.trim());
      }
    }

    List<String> categoryList = categories.toList();

    // Ensure _selectedCategory exists in the list, or reset to 'All'
    if (_selectedCategory != 'All' &&
        !categoryList.contains(_selectedCategory)) {
      setState(() {
        _selectedCategory = 'All';
      });
    }

    return categoryList;
  }

  // Create filtered and categorized stores
  Map<String, List<Store>> _getFilteredCategorizedStores() {
    final filteredStores = _getFilteredStores();

    // If searching or filtering, show a flat list
    if (_searchQuery.isNotEmpty ||
        _selectedCategory != 'All' ||
        _priceRange != 'All' ||
        _onlyFeatured) {
      return {'Filtered Results': filteredStores};
    }

    // Otherwise group by category
    final Map<String, List<Store>> categorized = {};
    for (var store in filteredStores) {
      final category = store.category.isNotEmpty ? store.category : 'Other';

      if (!categorized.containsKey(category)) {
        categorized[category] = [];
      }

      categorized[category]!.add(store);
    }

    return categorized;
  }

  // Reset all filters
  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _priceRange = 'All';
      _onlyFeatured = false;
    });
  }

  Future<void> _loadStores() async {
    setState(() {
      _isLoading = true;
      _debugMessage = 'Loading stores...';
    });

    List<Store> storesToDisplay = [];

    try {
      print('Attempting to load stores for mall ID: ${widget.mall.id}');
      // Check if mall ID is valid before attempting to fetch
      if (widget.mall.id.isEmpty) {
        throw Exception("Mall ID is empty");
      }

      storesToDisplay = await _storeService.getStoresForMall(widget.mall.id);
      print('Loaded ${storesToDisplay.length} stores from Firestore.');

      if (storesToDisplay.isEmpty) {
        _debugMessage = 'No stores found in Firestore. Using mall.stores list.';
        print(_debugMessage);
        // Try to create stores from the names listed in the mall document
        storesToDisplay = _createMockStoresFromNames();
      }
    } catch (e) {
      print(
        'Error loading stores: $e. Falling back to mall.stores list or defaults.',
      );
      _debugMessage = 'Error loading live store data: $e.';

      // Fallback: Try to create stores from the names listed in the mall document
      storesToDisplay = _createMockStoresFromNames();
    }

    // If still no stores, use default examples as a last resort
    if (storesToDisplay.isEmpty) {
      _debugMessage = 'No stores found. Using default examples.';
      print(_debugMessage);
      storesToDisplay = _createDefaultStores();
    }

    // Group stores by category with safety checks
    final Map<String, List<Store>> categorized = {};
    for (var store in storesToDisplay) {
      // Ensure category is never null
      final category = store.category.isNotEmpty ? store.category : 'Other';

      if (!categorized.containsKey(category)) {
        categorized[category] = [];
      }
      categorized[category]!.add(store);
    }

    if (mounted) {
      setState(() {
        _stores = storesToDisplay;
        _categorizedStores = categorized;
        _isLoading = false;
      });
    }

    // Ensure _selectedCategory is valid after loading stores
    _resetFilters();
  }

  // Create mock stores from mall.stores (list of names)
  List<Store> _createMockStoresFromNames() {
    if (widget.mall.stores.isNotEmpty) {
      print('Creating mock stores from ${widget.mall.stores.length} names');

      return widget.mall.stores
          .map((storeNameDynamic) {
            // Handle both String and Map data
            if (storeNameDynamic is String) {
              return Store(
                id:
                    'mock-${storeNameDynamic.hashCode}-${DateTime.now().millisecondsSinceEpoch}',
                name: storeNameDynamic,
                description:
                    'Basic information for $storeNameDynamic in ${widget.mall.name}.',
                category: 'General',
                imageUrl: '',
                mallId: widget.mall.id,
                mallName: widget.mall.name,
                isFeatured: false,
                floorNumber: 1,
                contactInfo: '',
                openingHours: '',
              );
            } else if (storeNameDynamic is Map) {
              // Handle if the store data is a Map
              return Store(
                id:
                    'mock-${storeNameDynamic['name']?.hashCode ?? DateTime.now().millisecondsSinceEpoch}',
                name: storeNameDynamic['name'] ?? 'Unnamed Store',
                description:
                    storeNameDynamic['description'] ??
                    'No description available',
                category: storeNameDynamic['category'] ?? 'General',
                imageUrl: storeNameDynamic['imageUrl'] ?? '',
                mallId: widget.mall.id,
                mallName: widget.mall.name,
                isFeatured: storeNameDynamic['isFeatured'] ?? false,
                floorNumber: storeNameDynamic['floorNumber'] ?? 1,
                contactInfo: storeNameDynamic['contactInfo'] ?? '',
                openingHours: storeNameDynamic['openingHours'] ?? '',
              );
            }
            return null;
          })
          .whereType<Store>()
          .toList();
    }

    print('mall.stores is empty');
    return [];
  }

  // Create default stores for testing
  List<Store> _createDefaultStores() {
    return [
      Store(
        id: 'default-1',
        name: 'Fashion Boutique',
        description: 'Premium clothing store',
        category: 'Fashion',
        imageUrl: '',
        mallId: widget.mall.id,
        mallName: widget.mall.name,
        isFeatured: true,
        floorNumber: 1,
        contactInfo: '',
        openingHours: '10:00 AM - 9:00 PM',
      ),
      Store(
        id: 'default-2',
        name: 'Tech Haven',
        description: 'Electronics and gadgets',
        category: 'Electronics',
        imageUrl: '',
        mallId: widget.mall.id,
        mallName: widget.mall.name,
        isFeatured: false,
        floorNumber: 2,
        contactInfo: '',
        openingHours: '10:00 AM - 9:00 PM',
      ),
      Store(
        id: 'default-3',
        name: 'Home Decor',
        description: 'Interior design and home accessories',
        category: 'Home & Garden',
        imageUrl: '',
        mallId: widget.mall.id,
        mallName: widget.mall.name,
        isFeatured: true,
        floorNumber: 1,
        contactInfo: '',
        openingHours: '10:00 AM - 9:00 PM',
      ),
    ];
  }

  void _handleFallbackStores() {
    List<Store> fallbackStores = _createDefaultStores();

    final Map<String, List<Store>> categorized = {};
    for (var store in fallbackStores) {
      final category = store.category.isNotEmpty ? store.category : 'Other';

      if (!categorized.containsKey(category)) {
        categorized[category] = [];
      }

      categorized[category]!.add(store);
    }

    setState(() {
      _stores = fallbackStores;
      _categorizedStores = categorized;
      _isLoading = false;
    });
  }

  Widget _buildBackgroundImage(String imageUrl) {
    if (imageUrl.startsWith('data:image') ||
        RegExp(
          r'^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$',
        ).hasMatch(imageUrl)) {
      // Handle base64 image
      try {
        String base64String = imageUrl;
        if (imageUrl.contains(',')) {
          base64String = imageUrl.split(',').last;
        }

        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => _buildFallbackBackground(),
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return _buildFallbackBackground();
      }
    } else if (imageUrl.startsWith('http')) {
      // Handle network image
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Container(
              color: secondaryColor,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        errorWidget: (context, url, error) => _buildFallbackBackground(),
      );
    } else {
      // Try as asset image
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => _buildFallbackBackground(),
      );
    }
  }

  Widget _buildFallbackBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [secondaryColor, primaryColor],
        ),
      ),
    );
  }

  IconData getCategoryIcon(String category) {
    final lowercaseCategory = category.toLowerCase();

    if (lowercaseCategory.contains('fashion') ||
        lowercaseCategory.contains('clothing'))
      return Icons.shopping_bag;
    else if (lowercaseCategory.contains('electronics'))
      return Icons.devices;
    else if (lowercaseCategory.contains('food') ||
        lowercaseCategory.contains('restaurant'))
      return Icons.restaurant;
    else if (lowercaseCategory.contains('home'))
      return Icons.home;
    else if (lowercaseCategory.contains('beauty'))
      return Icons.spa;
    else if (lowercaseCategory.contains('sport'))
      return Icons.sports_basketball;
    else if (lowercaseCategory.contains('book') ||
        lowercaseCategory.contains('media'))
      return Icons.book;
    else if (lowercaseCategory == 'all' ||
        lowercaseCategory == 'filtered results')
      return Icons.category;
    else
      return Icons.storefront;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
               iconTheme: const IconThemeData(color: Colors.white),
              backgroundColor: Colors.transparent,
              expandedHeight: 200,
              floating: true,
              pinned: true,
              snap: false,
              title: Text(
                widget.mall.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Color.fromARGB(150, 0, 0, 0),
                    ),
                  ],
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Mall image background
                    widget.mall.imageUrls.isNotEmpty
                        ? _buildBackgroundImage(widget.mall.imageUrls.first)
                        : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [secondaryColor, primaryColor],
                            ),
                          ),
                        ),

                    // Gradient overlay for text readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),

                    // Bottom mall info
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explore our stores',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 1),
                                    blurRadius: 3.0,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Tags row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.mall.type,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        widget.mall.rating.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  onPressed: _toggleFilterVisibility,
                  tooltip: 'Filter stores',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadStores,
                  tooltip: 'Refresh stores',
                ),
              ],
            ),
          ];
        },
        body: Stack(
          children: [
            // Main content
            if (_isLoading)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Loading stores...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else if (_stores.isEmpty)
              _buildEmptyState()
            else
              _buildStoresContent(),

            // Filter panel that slides down
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizeTransition(
                sizeFactor: _filterAnimation,
                child: _buildFilterPanel(),
              ),
            ),
          ],
        ),
      ),
      
    );
  }

  // Toggle one category
  void _toggleCategory(String category) {
    setState(() {
      _categoryExpansionState[category] =
          !(_categoryExpansionState[category] ?? true);
    });
  }

  // Filter panel UI
  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 18, color: secondaryColor),
              const SizedBox(width: 8),
              Text(
                'Filter Stores',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: secondaryColor,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset'),
                onPressed: _resetFilters,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search stores...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Filter options in a row
          Row(
            children: [
              // Category dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCategory,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        items:
                            _getCategories()
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(
                                      category,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Price range dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price Range',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _priceRange,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        items: const [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text(
                              'All Prices',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Budget',
                            child: Text(
                              'Budget',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Mid-range',
                            child: Text(
                              'Mid-range',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Luxury',
                            child: Text(
                              'Luxury',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _priceRange = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Featured stores only toggle
          Row(
            children: [
              Checkbox(
                value: _onlyFeatured,
                activeColor: secondaryColor,
                onChanged: (value) {
                  setState(() {
                    _onlyFeatured = value ?? false;
                  });
                },
              ),
              Row(
                children: [
                  const Text('Show only featured stores'),
                  const SizedBox(width: 4),
                  Icon(Icons.star, size: 16, color: primaryColor),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Main stores content
  Widget _buildStoresContent() {
    // Get the filtered and possibly categorized stores
    final filteredCategorizedStores = _getFilteredCategorizedStores();

    // If no stores match the current filters
    if (filteredCategorizedStores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No stores match your filters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 2) Removed mall info card
        // _buildMallCard(),
        // const SizedBox(height: 24),

        // Category cards (Optional)
        if (_getCategories().length > 1) _buildCategoryCards(),

        // Display count of matching items if search/filter is active
        if (_searchQuery.isNotEmpty ||
            _selectedCategory != 'All' ||
            _priceRange != 'All' ||
            _onlyFeatured)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Found ${_getFilteredStores().length} matching stores',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Store items
        ...filteredCategorizedStores.entries.map((entry) {
          // Check if stores list is valid before rendering
          if (entry.value.isEmpty) return const SizedBox.shrink();

          // Render category section with proper error handling
          return _buildCategorySection(
            entry.key.isNotEmpty ? entry.key : 'Other',
            entry.value,
          );
        }),
      ],
    );
  }

  // 3) Modify this section to collapse/expand
  Widget _buildCategorySection(String category, List<Store> stores) {
    final isExpanded = _categoryExpansionState[category] ?? true;

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header row ...
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [secondaryColor, secondaryColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: secondaryColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  getCategoryIcon(category),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Category name with item count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stores.length} ${stores.length == 1 ? 'store' : 'stores'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Optional: Add a toggle to collapse/expand category
              IconButton(
                icon: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: secondaryColor,
                ),
                onPressed: () => _toggleCategory(category),
                splashRadius: 24,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Modern gradient divider
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  secondaryColor,
                  secondaryColor.withOpacity(0.5),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.7, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),

          // animated collapse/expand of the stores list
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              children: <Widget>[
                if (isExpanded) ...stores.map((s) => _buildStoreCard(s)),
                if (isExpanded) const SizedBox(height: 16),
                if (!isExpanded) const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modernized store card
  Widget _buildStoreCard(Store store) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to store details or show detailed info
          },
          child: Stack(
            children: [
              Column(
                children: [
                  // Image with curved top corners
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      child:
                          store.imageUrl.isNotEmpty
                              ? Hero(
                                tag: 'store-${store.id}',
                                child: _buildImageWidget(store.imageUrl),
                              )
                              : _buildImagePlaceholder(store.name),
                    ),
                  ),

                  // Content section
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and floor in a row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                store.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Floor ${store.floorNumber}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Description
                        if (store.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            store.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              height: 1.3,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Footer row with category and hours
                        Row(
                          children: [
                            if (store.category.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  store.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),

                            const Spacer(),

                            // Opening hours or contact info
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: secondaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    store.openingHours.isNotEmpty
                                        ? store.openingHours
                                        : 'Regular Hours',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (store.isFeatured)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.star, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Featured',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(String storeName) {
    // Create a visually pleasing placeholder based on store name
    final colorSeed = storeName.hashCode;
    final colors = [
      Colors.amber[200],
      Colors.lightBlue[200],
      Colors.lightGreen[200],
      Colors.purple[200],
      Colors.orange[200],
      Colors.teal[200],
    ];
    final color = colors[colorSeed % colors.length];

    return Container(
      color: color,
      child: Center(
        child: Text(
          storeName.isNotEmpty ? storeName[0].toUpperCase() : "?",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imageSource) {
    if (imageSource.isEmpty) {
      return _buildImagePlaceholder("No Image");
    }

    try {
      if (imageSource.startsWith('data:image')) {
        final parts = imageSource.split(',');
        if (parts.length < 2) {
          return _buildImagePlaceholder("Invalid Image");
        }

        final base64String = parts[1];
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading base64 image: $error');
            return _buildImagePlaceholder("Error");
          },
        );
      } else if (RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageSource)) {
        return Image.memory(
          base64Decode(imageSource),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder("Error");
          },
        );
      } else {
        return CachedNetworkImage(
          imageUrl: imageSource,
          fit: BoxFit.cover,
          placeholder:
              (context, url) =>
                  Center(child: CircularProgressIndicator(color: primaryColor)),
          errorWidget:
              (context, url, error) => _buildImagePlaceholder("Network Error"),
        );
      }
    } catch (e) {
      print('Error handling image: $e');
      return _buildImagePlaceholder("Error");
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_mall_directory_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No Stores Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'This mall doesn\'t have any stores yet. Add the first one!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
         
          const SizedBox(height: 16),
          if (_debugMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _debugMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCards() {
    final categories = _getCategories();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == _selectedCategory;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? secondaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Colors.white.withOpacity(0.2)
                                  : secondaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          getCategoryIcon(category),
                          color: isSelected ? Colors.white : secondaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (category != 'All') ...[
                        const SizedBox(height: 4),
                        Text(
                          _stores
                              .where((s) => s.category == category)
                              .length
                              .toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isSelected ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
