import SwiftUI
import SwiftData

struct ExpensesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var showAdd = false
    @State private var editingExpense: Expense?
    @State private var showEdit = false

    var body: some View {
        Group {
            if expenses.isEmpty {
                ContentUnavailableView {
                    Label("لسه مفيش مصروفات", systemImage: "tray")
                        .font(AppFont.title2())
                } description: {
                    Text("أضف مصروف يدويًا أو استخدم الصوت والكاميرا.")
                        .font(AppFont.body())
                }
            } else {
                List {
                    ForEach(expenses) { expense in
                        Button {
                            editingExpense = expense
                            showEdit = true
                        } label: {
                            ExpenseRowView(expense: expense)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.plain)
                .font(AppFont.body())
            }
        }
        .environment(\.font, AppFont.body())
        .background(BrandTheme.foam.ignoresSafeArea())
        .navigationTitle("المصروفات")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                ExpenseFormView(mode: .create)
            }
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack {
                if let editingExpense {
                    ExpenseFormView(mode: .edit(editingExpense))
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(expenses[index])
        }
    }
}
