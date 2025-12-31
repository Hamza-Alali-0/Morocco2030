import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/restaurant/menu_item_model.dart';
import 'package:flutter_application_1/restaurant/menu_service.dart';
import 'package:flutter_application_1/restaurant/restaurant_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MenuDetailScreen extends StatefulWidget {
  final Restaurant restaurant;

  const MenuDetailScreen({Key? key, required this.restaurant})
    : super(key: key);

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen>
    with SingleTickerProviderStateMixin {
  final MenuService _menuService = MenuService();
  bool _isLoading = true;
  List<MenuItem> _menuItems = [];
  Map<String, List<MenuItem>> _categorizedItems = {};

  // Filter state variables
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _onlyBestsellers = false;
  String _sortBy = 'Default'; // Default, Price: Low to High, Price: High to Low
  bool _showFilters = false;

  // Colors matching your app theme
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);
  final Color backgroundColor = const Color(0xFFF9F9F9);

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  // Filter menu items based on criteria
  List<MenuItem> _getFilteredMenuItems() {
    List<MenuItem> filteredItems = List.from(_menuItems);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredItems =
          filteredItems
              .where(
                (item) =>
                    item.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    item.description.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      filteredItems =
          filteredItems
              .where((item) => item.category == _selectedCategory)
              .toList();
    }

    // Filter by bestseller
    if (_onlyBestsellers) {
      filteredItems = filteredItems.where((item) => item.isBestseller).toList();
    }

    // Sort items
    if (_sortBy == 'Price: Low to High') {
      filteredItems.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Price: High to Low') {
      filteredItems.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'Name: A-Z') {
      filteredItems.sort((a, b) => a.name.compareTo(b.name));
    }

    return filteredItems;
  }

  // Get all unique categories for filter dropdown
  List<String> _getCategories() {
    final Set<String> categories = {'All'};
    for (var item in _menuItems) {
      if (item.category.isNotEmpty) {
        categories.add(item.category);
      }
    }
    return categories.toList()..sort();
  }

  // Create filtered and categorized items
  Map<String, List<MenuItem>> _getFilteredCategorizedItems() {
    final filteredItems = _getFilteredMenuItems();

    // If searching is active, we'll show items in a flat list
    if (_searchQuery.isNotEmpty) {
      return {'Search Results': filteredItems};
    }

    // Otherwise group by category
    final Map<String, List<MenuItem>> categorized = {};

    for (var item in filteredItems) {
      final category = item.category.isNotEmpty ? item.category : 'Other';

      if (!categorized.containsKey(category)) {
        categorized[category] = [];
      }

      categorized[category]!.add(item);
    }

    return categorized;
  }

  // Reset all filters
  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _onlyBestsellers = false;
      _sortBy = 'Default';
    });
  }

  Future<void> _loadMenuItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<MenuItem> menuItems = [];

      try {
        // Try to fetch from Firestore first
        menuItems = await _menuService.getMenuForRestaurant(
          widget.restaurant.id,
        );
      } catch (e) {
        print('Error loading from Firestore: $e');
        // Create mock menu items from restaurant.menuItems
        menuItems = _createMockMenuItems();
      }

      // If no items, fallback to creating items from restaurant.menuItems
      if (menuItems.isEmpty && widget.restaurant.menuItems.isNotEmpty) {
        menuItems = _createMockMenuItems();
      }

      // Group items by category
      final Map<String, List<MenuItem>> categorized = {};
      for (var item in menuItems) {
        final category = item.category.isNotEmpty ? item.category : 'Other';
        if (!categorized.containsKey(category)) {
          categorized[category] = [];
        }
        categorized[category]!.add(item);
      }

      setState(() {
        _menuItems = menuItems;
        _categorizedItems = categorized;
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _loadMenuItems: $e');
      // Create backup items if all else fails
      _handleFallbackItems();
    }
  }

  // Create mock menu items from restaurant.menuItems
  List<MenuItem> _createMockMenuItems() {
    List<MenuItem> mockItems = [];
    int index = 0;

    if (widget.restaurant.menuItems.isEmpty) {
      return _createDefaultMenuItems(); // Create some default items
    }

    for (var itemName in widget.restaurant.menuItems) {
      // Create different categories for variety
      final categories = [
        'Starters',
        'Main Course',
        'Desserts',
        'Beverages',
        'Specials',
      ];
      final category = categories[index % categories.length];

      // Set some items as bestsellers
      final isBestseller = index % 3 == 0; // Make every third item a bestseller

      mockItems.add(
        MenuItem(
          id: 'mock-${index}',
          name: itemName,
          price: 50.0 + (index * 10),
          description: 'Delicious $itemName prepared with fresh ingredients',
          imageUrl: '',
          category: category,
          restaurantId: widget.restaurant.id,
          restaurantName: widget.restaurant.name,
          cityId: widget.restaurant.cityId,
          isBestseller: isBestseller,
        ),
      );

      index++;
    }

    return mockItems;
  }

  // Create some default menu items
  List<MenuItem> _createDefaultMenuItems() {
    return [
      MenuItem(
        id: 'default-1',
        name: 'House Special',
        price: 120.0,
        description: 'Chef\'s special recipe',
        category: 'Specials',
        restaurantId: widget.restaurant.id,
        restaurantName: widget.restaurant.name,
        cityId: widget.restaurant.cityId,
        isBestseller: true,
      ),
      MenuItem(
        id: 'default-2',
        name: 'Fresh Salad',
        price: 45.0,
        description: 'Mixed greens with our special dressing',
        category: 'Starters',
        restaurantId: widget.restaurant.id,
        restaurantName: widget.restaurant.name,
        cityId: widget.restaurant.cityId,
      ),
      MenuItem(
        id: 'default-3',
        name: 'Grilled Chicken',
        price: 85.0,
        description: 'Served with vegetables and rice',
        category: 'Main Course',
        restaurantId: widget.restaurant.id,
        restaurantName: widget.restaurant.name,
        cityId: widget.restaurant.cityId,
        isBestseller: true,
      ),
      MenuItem(
        id: 'default-4',
        name: 'Chocolate Cake',
        price: 35.0,
        description: 'Rich chocolate cake with vanilla ice cream',
        category: 'Desserts',
        restaurantId: widget.restaurant.id,
        restaurantName: widget.restaurant.name,
        cityId: widget.restaurant.cityId,
      ),
    ];
  }

  // Fallback when everything fails
  void _handleFallbackItems() {
    List<MenuItem> fallbackItems = _createDefaultMenuItems();

    // Create categories
    final Map<String, List<MenuItem>> categorized = {};
    for (var item in fallbackItems) {
      final category = item.category.isNotEmpty ? item.category : 'Menu';
      if (!categorized.containsKey(category)) {
        categorized[category] = [];
      }
      categorized[category]!.add(item);
    }

    setState(() {
      _menuItems = fallbackItems;
      _categorizedItems = categorized;
      _isLoading = false;
    });
  }

  IconData getCategoryIcon(String category) {
    final lowercaseCategory = category.toLowerCase();

    if (lowercaseCategory.contains('starter') ||
        lowercaseCategory.contains('appetizer'))
      return Icons.lunch_dining;
    else if (lowercaseCategory.contains('main') ||
        lowercaseCategory.contains('course'))
      return Icons.dinner_dining;
    else if (lowercaseCategory.contains('dessert'))
      return Icons.icecream;
    else if (lowercaseCategory.contains('beverage') ||
        lowercaseCategory.contains('drink'))
      return Icons.local_drink;
    else if (lowercaseCategory.contains('breakfast'))
      return Icons.free_breakfast;
    else if (lowercaseCategory.contains('special'))
      return Icons.stars;
    else if (lowercaseCategory.contains('salad'))
      return Icons.spa;
    else if (lowercaseCategory.contains('soup'))
      return Icons.soup_kitchen;
    else if (lowercaseCategory.contains('pasta') ||
        lowercaseCategory.contains('noodle'))
      return Icons.ramen_dining;
    else if (lowercaseCategory == 'search results')
      return Icons.search;
    else if (lowercaseCategory == 'all')
      return Icons.restaurant_menu;
    else
      return Icons.fastfood;
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategorizedItems = _getFilteredCategorizedItems();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              title: Text(
                'Menu - ${widget.restaurant.name}',
                style: const TextStyle(
                  fontSize: 18,
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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Restaurant image as background
                    widget.restaurant.imageUrls.isNotEmpty
                        ? _buildImageWidget(widget.restaurant.imageUrls.first)
                        : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                secondaryColor,
                                secondaryColor.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.restaurant_menu,
                              size: 50,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),

                    // Gradient overlay for better text readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),

                    // Restaurant info at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 40,
                          top: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Restaurant info pills
                            Row(
                              children: [
                                // Cuisine type
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    widget.restaurant.cuisine,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Rating pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: primaryColor,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.restaurant.rating.toString(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Menu items count
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.restaurant_menu,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${_menuItems.length} items",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
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
                // Toggle filter view
                IconButton(
                  icon: Icon(
                    _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  ),
                  tooltip: _showFilters ? 'Hide filters' : 'Show filters',
                  color: Colors.white,
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                ),
                // Clear filters button if any filters are active
                if (_searchQuery.isNotEmpty ||
                    _selectedCategory != 'All' ||
                    _onlyBestsellers ||
                    _sortBy != 'Default')
                  IconButton(
                    icon: const Icon(Icons.clear_all, color: Colors.white),
                    tooltip: 'Clear filters',
                    onPressed: _resetFilters,
                  ),
              ],
            ),
          ];
        },
        body: Column(
          children: [
            // Search and filter bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search menu items',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                          : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),

            // Expanded filter section (conditionally visible)
            if (_showFilters)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sort options
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sort by:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (var option in [
                                'Default',
                                'Price: Low to High',
                                'Price: High to Low',
                                'Name: A-Z',
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(option),
                                    selected: _sortBy == option,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _sortBy = option;
                                        });
                                      }
                                    },
                                    selectedColor: secondaryColor,
                                    labelStyle: TextStyle(
                                      color:
                                          _sortBy == option
                                              ? Colors.white
                                              : Colors.black87,
                                      fontWeight:
                                          _sortBy == option
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Bestseller toggle
                    Row(
                      children: [
                        Icon(Icons.star, color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Bestsellers only:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Switch(
                          value: _onlyBestsellers,
                          onChanged: (value) {
                            setState(() {
                              _onlyBestsellers = value;
                            });
                          },
                          activeColor: primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Category filter chips - always visible
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Horizontal list of category chips
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _getCategories().length,
                      itemBuilder: (context, index) {
                        final category = _getCategories()[index];
                        final isSelected = _selectedCategory == category;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? category : 'All';
                              });
                            },
                            avatar: Icon(
                              getCategoryIcon(category),
                              size: 18,
                              color: isSelected ? Colors.white : secondaryColor,
                            ),
                            backgroundColor: Colors.grey[100],
                            selectedColor: secondaryColor,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Container(height: 1, color: Colors.grey[200]),

            // Applied filters summary
            if (_searchQuery.isNotEmpty ||
                _selectedCategory != 'All' ||
                _onlyBestsellers ||
                _sortBy != 'Default')
              Container(
                color: Colors.grey[50],
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 16, color: secondaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Filters applied: ${_getAppliedFiltersText()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: _resetFilters,
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(50, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),

            // Menu content
            Expanded(
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                      : filteredCategorizedItems.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.no_food,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No menu items found with\nthese filters',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _resetFilters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Clear Filters'),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: filteredCategorizedItems.length,
                        itemBuilder: (context, index) {
                          final category = filteredCategorizedItems.keys
                              .elementAt(index);
                          final items = filteredCategorizedItems[category]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category header
                              Container(
                                color: Colors.grey[50],
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  8,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      getCategoryIcon(category),
                                      color: secondaryColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: secondaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${items.length}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Menu items for this category
                              ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: items.length,
                                separatorBuilder:
                                    (context, index) => Divider(
                                      height: 1,
                                      indent: 16,
                                      endIndent: 16,
                                      color: Colors.grey[200],
                                    ),
                                itemBuilder: (context, itemIndex) {
                                  final item = items[itemIndex];
                                  return _buildMenuItemCard(item);
                                },
                              ),

                              // Add space between categories
                              Container(height: 12, color: Colors.grey[50]),
                            ],
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAppliedFiltersText() {
    List<String> filters = [];

    if (_searchQuery.isNotEmpty) filters.add('Search: "${_searchQuery}"');

    if (_selectedCategory != 'All') filters.add('Category: $_selectedCategory');

    if (_onlyBestsellers) filters.add('Bestsellers only');

    if (_sortBy != 'Default') filters.add('Sort: $_sortBy');

    return filters.join(', ');
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return InkWell(
      onTap: () {
        // Show item details or add to cart
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${item.name} to cart'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item image or icon
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 70,
                height: 70,
                child:
                    item.imageUrl.isNotEmpty
                        ? _buildItemImage(item.imageUrl)
                        : Container(
                          color: primaryColor.withOpacity(0.1),
                          child: Center(
                            child: Icon(
                              getCategoryIcon(item.category),
                              size: 30,
                              color: primaryColor,
                            ),
                          ),
                        ),
              ),
            ),

            const SizedBox(width: 12),

            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item name with bestseller badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (item.isBestseller)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.star, color: Colors.white, size: 12),
                              SizedBox(width: 2),
                              Text(
                                'Bestseller',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Item description
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Price
                  Text(
                    '${item.price.toStringAsFixed(2)} MAD',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(String imageUrl) {
    if (imageUrl.startsWith('data:image') ||
        RegExp(
          r'^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$',
        ).hasMatch(imageUrl)) {
      try {
        String base64String = imageUrl;
        if (imageUrl.contains(',')) {
          base64String = imageUrl.split(',')[1];
        }
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
        );
      } catch (e) {
        return _buildErrorImage();
      }
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Container(
              color: Colors.grey[300],
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryColor,
                ),
              ),
            ),
        errorWidget: (context, url, error) => _buildErrorImage(),
      );
    }
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.restaurant, size: 30, color: Colors.grey[400]),
    );
  }

  Widget _buildImageWidget(String imageSource) {
    if (imageSource.startsWith('data:image') ||
        RegExp(
          r'^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$',
        ).hasMatch(imageSource)) {
      String base64String = imageSource;
      if (imageSource.contains(',')) {
        base64String = imageSource.split(',')[1];
      }

      try {
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildHeaderErrorImage();
          },
        );
      } catch (e) {
        return _buildHeaderErrorImage();
      }
    } else {
      return CachedNetworkImage(
        imageUrl: imageSource,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder:
            (context, url) => Container(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
        errorWidget: (context, url, error) => _buildHeaderErrorImage(),
      );
    }
  }

  Widget _buildHeaderErrorImage() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 60, color: Colors.white70),
            const SizedBox(height: 8),
            Text(
              "Image unavailable",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
