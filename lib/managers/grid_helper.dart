class GridHelper {
  final int size;

  GridHelper(this.size);

  int get totalTiles => size * size;

  // Generate vertical order for swipe up/down
  List<int> get verticalOrder {
    List<int> order = [];
    for (int col = 0; col < size; col++) {
      for (int row = size - 1; row >= 0; row--) {
        order.add(row * size + col);
      }
    }
    return order;
  }

  // Check if two indexes are in the same row
  bool inSameRow(int index1, int index2) {
    return (index1 ~/ size) == (index2 ~/ size);
  }

  // Check if indexes are in range (same row or column)
  bool inRange(int index, int nextIndex) {
    return inSameRow(index, nextIndex);
  }

  // Get row number from index
  int getRow(int index) {
    return index ~/ size;
  }

  // Get column number from index
  int getCol(int index) {
    return index % size;
  }
}
