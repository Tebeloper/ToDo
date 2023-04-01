//
//  ViewController.swift
//  ToDo
//
//  Created by Dimitrios Gkarlemos on 28/03/2023.
//

import UIKit

class CategoryViewController: UIViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    private var category = [ToDoListItem]()
    
    
    let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self,
                       forCellReuseIdentifier: "cell")
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ToDo"
        
        view.addSubview(tableView)
        
        getAllCategories()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.frame = view.bounds
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(didTapAdd))
    }
    
    @objc private func didTapAdd() {
        
        let alert = UIAlertController(title: "New Item",
                                      message: "Enter new item",
                                      preferredStyle: .alert)
        
        alert.addTextField()
        alert.addAction(UIAlertAction(title: "Submit", style: .cancel, handler: {[weak self] _ in
            guard let field = alert.textFields?.first,
                  let text = field.text,
                  !text.isEmpty else {return}
            
            self?.createCategory(name: text)
        }))
        present(alert, animated: true)
    }
    
    
    // MARK: - Core Data
    
    // Create
    func createCategory(name: String) {
        let newItem = ToDoListItem(context: context)
        newItem.name = name
        
        do {
            try context.save()
            getAllCategories()
        }
        catch {
            print("Error creating new Category... \(error)")
        }
    }
    // Read
    func getAllCategories() {
        do {
            category = try context.fetch(ToDoListItem.fetchRequest())
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        catch {
            print("Error reading the data... \(error)")
            
        }
    }
    //Update
    func updateCategory(category: ToDoListItem, newName: String) {
        category.name = newName
        
        do {
            try context.save()
            getAllCategories()
        }
        catch {
            print("Error updating the data... \(error)")
        }
    }
    // Delete
    func deleteCategory(category: ToDoListItem) {
        context.delete(category)
        
        do {
            try context.save()
            getAllCategories()
        }
        catch {
            print("Error deleting the data... \(error)")
        }
    }
    
    // Save
    func saveData() {
        do {
            try context.save()
        } catch {
            print("Error saving the data... \(error)")
        }
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension CategoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    // UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return category.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let category = category[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = category.name
        cell.accessoryType = category.done ? .checkmark : .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let category = category[indexPath.row]
        
        print(indexPath.row)
    }
    
    // Swipe to Delete & Edit
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let category = category[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            self?.deleteCategory(category: category)
            self?.tableView.deleteRows(at: [indexPath], with: .automatic)
            completionHandler(true)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] (action, view, completionHandler) in
            let alert = UIAlertController(title: "Edit item",
                                          message: "Edit your item",
                                          preferredStyle: .alert)
            
            alert.addTextField(configurationHandler: nil)
            alert.textFields?.first?.text = category.name
            
            alert.addAction(UIAlertAction(title: "Save", style: .cancel, handler: { [weak self] _ in
                guard let field = alert.textFields?.first,
                      let newName = field.text,
                      !newName.isEmpty else {return}
                
                self?.updateCategory(category: category, newName: newName)
            }))
            
            self?.present(alert, animated: true)
            completionHandler(true)
        }
        
        let doneTitle = category.done ? "Unmark" : "Mark"
        let doneAction = UIContextualAction(style: .normal, title: doneTitle) { [weak self] (action, view, completionHandler) in
            
            category.done = !category.done
            self?.saveData()
        }
        
        editAction.backgroundColor = .systemOrange
        doneAction.backgroundColor = category.done ? .systemPurple : .systemBlue
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction, doneAction])
        return configuration
    }
}

