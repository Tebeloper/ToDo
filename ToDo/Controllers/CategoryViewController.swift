//
//  ViewController.swift
//  ToDo
//
//  Created by Dimitrios Gkarlemos on 28/03/2023.
//

import UIKit

class CategoryViewController: UIViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    private var model = [ToDoListItem]()
    
    
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
        
        getAllItems()
        
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
            
            self?.createItem(name: text)
        }))
        present(alert, animated: true)
    }
    
    
    // MARK: - Core Data
    
    // Create
    func createItem(name: String) {
        let newItem = ToDoListItem(context: context)
        newItem.name = name
        newItem.createdAt = Date()
        
        do {
            try context.save()
            getAllItems()
        }
        catch {
            print("Error creating new Category... \(error)")
        }
    }
    // Read
    func getAllItems() {
        do {
            model = try context.fetch(ToDoListItem.fetchRequest())
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        catch {
            print("Error reading the data... \(error)")
            
        }
    }
    //Update
    func updateItem(item: ToDoListItem, newName: String) {
        item.name = newName
        
        do {
            try context.save()
            getAllItems()
        }
        catch {
            print("Error updating the data... \(error)")
        }
    }
    // Delete
    func deleteItem(item: ToDoListItem) {
        context.delete(item)
        
        do {
            try context.save()
            getAllItems()
        }
        catch {
            print("Error deleting the data... \(error)")
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension CategoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    // UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = model[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = model.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = model[indexPath.row]
        
        let sheet = UIAlertController(title: "ActionSheet",
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
        sheet.addAction(UIAlertAction(title: "Edit", style: .default, handler: { [weak self] _ in
            let alert = UIAlertController(title: "Edit item",
                                          message: "Edit your item",
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
        }))
        
        sheet.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            self?.deleteItem(item: item)
        }))
        
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(sheet, animated: true)
    }
    
    // Swipe to Delete & Edit
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = model[indexPath.row]
        let newName = item.name!
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            self?.deleteItem(item: item)
            self?.tableView.deleteRows(at: [indexPath], with: .automatic)
            completionHandler(true)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] (action, view, completionHandler) in
            let alert = UIAlertController(title: "Edit item",
                                          message: "Edit your item",
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
        editAction.backgroundColor = .systemOrange
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        return configuration
    }
}

