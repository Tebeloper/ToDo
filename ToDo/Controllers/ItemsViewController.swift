//
//  ItemsViewController.swift
//  ToDo
//
//  Created by Dimitrios Gkarlemos on 03/04/2023.
//

import UIKit
import CoreData

class ItemsViewController: UIViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var pendingItem = [Items]()
    var doneItem = [Items]()
    
    var selectedCategory: Category? {
        didSet {
            loadData()
        }
    }
    
    let pendingTableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self,
                       forCellReuseIdentifier: "pending")
        return table
    }()
    
    let doneTableTitle: UILabel = {
        let doneTableTitle = UILabel()
        doneTableTitle.text = "Done ✓"
        doneTableTitle.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        doneTableTitle.isHidden = true
        return doneTableTitle
    }()
    
    let doneTableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self,
                       forCellReuseIdentifier: "done")
        return table
    }()
    
    
    let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search items..."
        return searchBar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        view.addSubview(pendingTableView)
        view.addSubview(doneTableTitle)
        view.addSubview(doneTableView)
        
        navigationItem.titleView = searchBar
        
        pendingTableView.delegate = self
        pendingTableView.dataSource = self
        
        doneTableView.delegate = self
        doneTableView.dataSource = self
        
        searchBar.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(didTapAdd))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        constrainTables()
        
        
    }
    
    @objc private func didTapAdd() {
        
        let alert = UIAlertController(title: "Create",
                                      message: "Enter new item",
                                      preferredStyle: .alert)
        alert.addTextField()
        alert.addAction(UIAlertAction(title: "Submit", style: .cancel, handler: {[weak self] _ in
            guard let field = alert.textFields?.first,
                  let text = field.text,
                  !text.isEmpty else {return}
            
            let trimmedString = text.trimmingCharacters(in: .whitespaces)
            self?.createItem(name: trimmedString)
        }))
        present(alert, animated: true)
    }
    
    func constrainTables() {
        
        // Add constraints to pendingTableView
        pendingTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pendingTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                                  constant: 5),
            pendingTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                      constant: 5),
            pendingTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                       constant: -5),
            pendingTableView.heightAnchor.constraint(equalToConstant: 350)
        ])
        
        // Add constraints to doneTableView
        doneTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneTableView.topAnchor.constraint(equalTo: pendingTableView.bottomAnchor,                                                    constant: 10),
            doneTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                   constant: 5),
            doneTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                    constant: -5),
            doneTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,                                                      constant: -5)
        ])
        
        // Add constraints to doneTableTitle
        doneTableTitle.translatesAutoresizingMaskIntoConstraints = false
        doneTableTitle.topAnchor.constraint(equalTo: doneTableView.topAnchor, constant: -40).isActive = true
        doneTableTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        doneTableTitle.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
    }
    
    // MARK: - Core Data
    
    // Create
    func createItem(name: String) {
        let newItem = Items(context: context)
        
        newItem.name = name
        newItem.parentCategory = selectedCategory
        
        pendingItem.append(newItem)
        
        saveItem()
    }
    
    // Read
    func getAllItems() {
        do {
            pendingItem = try context.fetch(Items.fetchRequest())
            DispatchQueue.main.async {
                self.pendingTableView.reloadData()
                self.doneTableView.reloadData()
            }
        }
        catch {
            print("Error reading data: \(error)")
        }
    }
    
    func loadData(with request: NSFetchRequest<Items> = Items.fetchRequest(), predicate: NSPredicate? = nil) {
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory!.name!)
        
        if let additionalPredicate = predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, additionalPredicate])
        } else {
            request.predicate = categoryPredicate
        }
        
        do {
            pendingItem = try context.fetch(request)
        } catch {
            print("Error reading data: \(error)")
        }
        pendingTableView.reloadData()
        doneTableView.reloadData()
    }
    
    //Update
    func updateItem(item: Items, newName: String) {
        item.name = newName
        do {
            try context.save()
        }
        catch {
            print("Error updating data: \(error)")
        }
        pendingTableView.reloadData()
        doneTableView.reloadData()
    }
    
    // Delete
    func deleteItem(item: Items) {
        context.delete(item)
        do {
            try context.save()
        }
        catch {
            print("Error deleting data: \(error)")
        }
        pendingTableView.reloadData()
        doneTableView.reloadData()
    }
    
    // Save
    func saveItem() {
        do {
            try context.save()
        } catch {
            print("Error saving data: \(error)")
        }
        pendingTableView.reloadData()
        doneTableView.reloadData()
    }
    
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ItemsViewController: UITableViewDelegate, UITableViewDataSource {
    
    // UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == pendingTableView {
            return pendingItem.count
        }
        if doneItem.count != 0 {
            doneTableTitle.isHidden = false
            return doneItem.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == pendingTableView {
            let item = pendingItem[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "pending", for: indexPath)
            cell.textLabel?.text = item.name
            cell.accessoryType = item.done ? .checkmark : .none
            
            return cell
        } else {
            let item = doneItem[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "done", for: indexPath)
            cell.textLabel?.text = item.name
            cell.accessoryType = item.done ? .checkmark : .none
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // UITableViewDelegate - Swipe to Edit, Mark/Unmark, Delete
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let pendingItem = pendingItem[indexPath.row]
        let doneTitle = pendingItem.done ? "Unmark" : "Mark"
        
        if tableView == pendingTableView {
            
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
                let actionSheet = UIAlertController(title: "Do you want to delete this category", message: "The category will permanently be deleted", preferredStyle: .actionSheet)
                actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                })
                actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                    self?.pendingItem.remove(at: indexPath.row)
                    self?.deleteItem(item: pendingItem)
                    self?.saveItem()
                })
                if let presenter = self?.presentedViewController {
                    presenter.dismiss(animated: true, completion: nil)
                }
                self?.present(actionSheet, animated: true, completion: nil)
            }
            let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] (action, view, completionHandler) in
                let alert = UIAlertController(title: "Edit",
                                              message: "Make the changes you want",
                                              preferredStyle: .alert)
                
                alert.addTextField(configurationHandler: nil)
                alert.textFields?.first?.text = pendingItem.name
                
                alert.addAction(UIAlertAction(title: "Save", style: .cancel, handler: { [weak self] _ in
                    guard let field = alert.textFields?.first,
                          let newName = field.text,
                          !newName.isEmpty else {return}
                    
                    self?.updateItem(item: pendingItem, newName: newName)
                }))
                
                self?.present(alert, animated: true)
                completionHandler(true)
            }
            
            let doneAction = UIContextualAction(style: .normal, title: doneTitle) { [weak self] (action, view, completionHandler) in
                
                let markedItem = self?.pendingItem.remove(at: indexPath.row)
                
                self?.doneItem.append(markedItem!)
                self?.saveItem()
                completionHandler(true)
            }
            
            editAction.backgroundColor = .systemOrange
            doneAction.backgroundColor = .systemBlue
            
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction, doneAction])
            return configuration
            
            // Doing stuff with doneTable
        } else {
            let doneItems = doneItem[indexPath.row]
            let doneTitle = pendingItem.done ? "Mark" : "Unmark"
            
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
                let actionSheet = UIAlertController(title: "Do you want to delete this category", message: "The category will permanently be deleted", preferredStyle: .actionSheet)
                actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                })
                actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                    self?.doneItem.remove(at: indexPath.row)
                    self?.deleteItem(item: doneItems)
                    self?.saveItem()
                    
                    if self?.doneItem.count == 0 {
                        self?.doneTableTitle.isHidden = true
                    }
                })
                if let presenter = self?.presentedViewController {
                    presenter.dismiss(animated: true, completion: nil)
                }
                self?.present(actionSheet, animated: true, completion: nil)
            }
            
            let doneAction = UIContextualAction(style: .normal, title: doneTitle) { [weak self] (action, view, completionHandler) in
                
                let markedItem = self?.doneItem.remove(at: indexPath.row)
                
                self?.pendingItem.append(markedItem!)
                if self?.doneItem.count == 0 {
                    self?.doneTableTitle.isHidden = true
                }
                
                self?.saveItem()
            }
            
            doneAction.backgroundColor = .systemBlue
            
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction, doneAction])
            return configuration
        }
    }
}

// MARK: - UISearchBarDelegate
extension ItemsViewController: UISearchBarDelegate {
    
    //RealTime search...
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.becomeFirstResponder()
        
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            loadData()
            searchBar.resignFirstResponder()
            return
        }
        
        let request: NSFetchRequest<Items> = Items.fetchRequest()
        
        let predicate = NSPredicate(format: "name CONTAINS[cd] %@", text)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        loadData(with: request, predicate: predicate)
    }
}
