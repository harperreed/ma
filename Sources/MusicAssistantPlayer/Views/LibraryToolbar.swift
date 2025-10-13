// ABOUTME: Toolbar for library browsing with sort, filter, and view options
// ABOUTME: Provides controls for customizing library display and filtering results

import SwiftUI

struct LibraryToolbar: View {
    @ObservedObject var viewModel: LibraryViewModel

    @State private var showingFilterSheet = false

    var body: some View {
        HStack(spacing: 16) {
            // Sort menu
            Menu {
                ForEach(LibrarySortOption.options(for: viewModel.selectedCategory), id: \.self) { option in
                    Button(action: {
                        Task {
                            await viewModel.updateSort(option)
                        }
                    }) {
                        HStack {
                            Text(option.displayName)
                            if viewModel.selectedSort == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14))
                    Text(viewModel.selectedSort.displayName)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(6)
            }

            // Filter button
            Button(action: {
                showingFilterSheet = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.selectedFilter.isEmpty ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 14))
                    Text("Filter")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(viewModel.selectedFilter.isEmpty ? .white.opacity(0.9) : .blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(6)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheet(
                filter: viewModel.selectedFilter,
                category: viewModel.selectedCategory,
                onApply: { filter in
                    Task {
                        await viewModel.updateFilter(filter)
                    }
                },
                onClear: {
                    Task {
                        await viewModel.updateFilter(LibraryFilter())
                    }
                }
            )
        }
    }
}

struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss

    let filter: LibraryFilter
    let category: LibraryCategory
    let onApply: (LibraryFilter) -> Void
    let onClear: () -> Void

    @State private var editedFilter: LibraryFilter

    init(filter: LibraryFilter, category: LibraryCategory, onApply: @escaping (LibraryFilter) -> Void, onClear: @escaping () -> Void) {
        self.filter = filter
        self.category = category
        self.onApply = onApply
        self.onClear = onClear
        _editedFilter = State(initialValue: filter)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Quick Filters")) {
                    Toggle("Favorites Only", isOn: $editedFilter.favoriteOnly)
                }

                Section(header: Text("Provider")) {
                    TextField("Provider name", text: Binding(
                        get: { editedFilter.provider ?? "" },
                        set: { editedFilter.provider = $0.isEmpty ? nil : $0 }
                    ))
                }

                if category == .albums {
                    Section(header: Text("Year Range")) {
                        HStack {
                            TextField("Min year", text: Binding(
                                get: {
                                    if let range = editedFilter.yearRange {
                                        return String(range.lowerBound)
                                    }
                                    return ""
                                },
                                set: { newValue in
                                    if let min = Int(newValue) {
                                        let max = editedFilter.yearRange?.upperBound ?? min
                                        editedFilter.yearRange = min...max
                                    } else if newValue.isEmpty {
                                        editedFilter.yearRange = nil
                                    }
                                }
                            ))
                            .textFieldStyle(.roundedBorder)

                            Text("-")

                            TextField("Max year", text: Binding(
                                get: {
                                    if let range = editedFilter.yearRange {
                                        return String(range.upperBound)
                                    }
                                    return ""
                                },
                                set: { newValue in
                                    if let max = Int(newValue) {
                                        let min = editedFilter.yearRange?.lowerBound ?? max
                                        editedFilter.yearRange = min...max
                                    } else if newValue.isEmpty {
                                        editedFilter.yearRange = nil
                                    }
                                }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                Section(header: Text("Genre")) {
                    TextField("Genre name", text: Binding(
                        get: { editedFilter.genre ?? "" },
                        set: { editedFilter.genre = $0.isEmpty ? nil : $0 }
                    ))
                }
            }
            .navigationTitle("Filter \(category.displayName)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(editedFilter)
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !editedFilter.isEmpty {
                    Button(action: {
                        onClear()
                        dismiss()
                    }) {
                        Text("Clear All Filters")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background(Color.white.opacity(0.05))
                }
            }
        }
    }
}

#Preview {
    let libraryService = LibraryService(client: nil)
    let viewModel = LibraryViewModel(libraryService: libraryService)

    LibraryToolbar(viewModel: viewModel)
        .background(Color.black)
}
