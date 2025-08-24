/// Simple shared store for category/service selections and filters.
/// Notifies nothing by itself; widgets call setState after mutating it.
class CategorySelectionStore {
  CategorySelectionStore._();
  static final CategorySelectionStore instance = CategorySelectionStore._();

  // categoryId -> {serviceKeys}
  final Map<String, Set<String>> selectedServices = <String, Set<String>>{};
  String? selectedCity;
  String sortBy = 'rating'; // 'rating' | 'price'
  String sortOrder = 'desc'; // 'asc' | 'desc'

  void reset() {
    selectedServices.clear();
    selectedCity = null;
    sortBy = 'rating';
    sortOrder = 'desc';
  }
}
