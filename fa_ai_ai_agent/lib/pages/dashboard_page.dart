                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF1E293B),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search company or ticker...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  suffixIcon: searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear,
                                              color: Colors.grey[600]),
                                          onPressed: () {
                                            searchController.clear();
                                            setState(() {
                                              searchResults = [];
                                            });
                                            _hideSearchResults();
                                          },
                                        )
                                      : Icon(Icons.search,
                                          color: Colors.grey[600]),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16), 