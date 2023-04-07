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
    
    var item = [Items]()
    
    var selectedCategory: Category? {
        didSet {
            loadData()
        }
    }
    
    let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self,
                       forCellReuseIdentifier: "cell")
        return table
    }()
    
    let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search items..."
        return searchBar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        navigationItem.titleView = searchBar
        
        getAllItems()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        
        searchBar.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(didTapAdd))
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
            
            self?.createItem(name: text)
        }))
        present(alert, animated: true)
    }
    
    // MARK: - Core Data
    
    // Create
    func createItem(name: String) {
        let newItem = Items(context: context)
        
        newItem.name = name
        newItem.parentCategory = selectedCategory
        item.append(newItem)
        
        saveItem()
    }
    
    // Read
    func getAllItems() {
        do {
            item = try context.fetch(Items.fetchRequest())
            DispatchQueue.main.async {
                self.tableView.reloadData()
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
            item = try context.fetch(request)
        } catch {
            print("Error reading data: \(error)")
        }
        tableView.reloadData()
    }
    
    //Update
    func updateItem(item: Items, newName: String) {
        item.name = newName
        do {
            try context.save()
            getAllItems()
        }
        catch {
            print("Error updating data: \(error)")
        }
    }
    
    // Delete
    func deleteItem(item: Items) {
        context.delete(item)
        do {
            try context.save()
            getAllItems()
        }
        catch {
            print("Error deleting data: \(error)")
        }
    }
    
    // Save
    func saveItem() {
        do {
            try context.save()
        } catch {
            print("Error saving data: \(error)")
        }
        tableView.reloadData()
    }
    
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ItemsViewController: UITableViewDelegate, UITableViewDataSource {
    
    // UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return item.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = item[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = item.name
        cell.accessoryType = item.done ? .checkmark : .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        print(item[indexPath.row])
    }
    
    // UITableViewDelegate - Swipe to Edit, Mark/Unmark, Delete
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = item[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            let actionSheet = UIAlertController(title: "Do you want to delete this category", message: "The category will permanently be deleted", preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionHandler(false)
            })
            actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                self?.deleteItem(item: item)
                self?.tableView.deleteRows(at: [indexPath], with: .automatic)
                completionHandler(true)
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
            alert.textFields?.first?.text = item.name
            
            alert.addAction(UIAlertAction(title: "Save", style: .cancel, handler: { [weak self] _ in
                guard let field = alert.textFields?.first,
                      let newName = field.text,
                      !newName.isEmpty else {return}
                
                self?.updateItem(item: item, newName: newName)
            }))
            
            self?.present(alert, animated: true)
            completionHandler(true)
        }
        
        let doneTitle = item.done ? "Unmark" : "Mark"
        let doneAction = UIContextualAction(style: .normal, title: doneTitle) { [weak self] (action, view, completionHandler) in
            
            item.done = !item.done
            self?.saveItem()
            completionHandler(true)
        }
        
        editAction.backgroundColor = .systemOrange
        doneAction.backgroundColor = .systemBlue
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction, doneAction])
        return configuration
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
