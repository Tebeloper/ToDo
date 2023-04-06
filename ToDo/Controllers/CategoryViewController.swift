//
//  ViewController.swift
//  ToDo
//
//  Created by Dimitrios Gkarlemos on 28/03/2023.
//

import UIKit

class CategoryViewController: UIViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var category = [Category]()
    
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
        
        let alert = UIAlertController(title: "Create",
                                      message: "Enter new category",
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
        let newItem = Category(context: context)
        newItem.name = name
        do {
            try context.save()
            getAllCategories()
        }
        catch {
            print("Error creating new category: \(error)")
        }
    }
    
    // Read
    func getAllCategories() {
        do {
            category = try context.fetch(Category.fetchRequest())
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        catch {
            print("Error reading data: \(error)")
            
        }
    }
    
    //Update
    func updateCategory(category: Category, newName: String) {
        category.name = newName
        do {
            try context.save()
            getAllCategories()
        }
        catch {
            print("Error updating data: \(error)")
        }
    }
    
    // Delete
    func deleteCategory(category: Category) {
        context.delete(category)
        do {
            try context.save()
            getAllCategories()
        }
        catch {
            print("Error deleting data: \(error)")
        }
    }
    
    // Save
    func saveData() {
        do {
            try context.save()
        } catch {
            print("Error saving data: \(error)")
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
        
        /* took me 3 days to find out why when i was creating an item from a category i was still has 'nil' parentCategory... "Joel Groomer" this man from Slack solved it!!! */
        
        //        tableView.deselectRow(at: indexPath, animated: true)
        
        performSegue(withIdentifier: "items", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        DispatchQueue.main.async {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRow(at: indexPath, animated: true)
                let selectedCategory = self.category[indexPath.row]
                let destinationVC = segue.destination as! ItemsViewController
                destinationVC.selectedCategory = selectedCategory
                destinationVC.title = selectedCategory.name
            }
        }
    }
    
    // UITableViewDelegate - Swipe to Edit, Mark/Unmark, Delete
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let category = category[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            let actionSheet = UIAlertController(title: "Do you want to delete this category", message: "The category will permanently be deleted", preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionHandler(false)
            })
            actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                self?.deleteCategory(category: category)
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
            completionHandler(true)
        }
        
        editAction.backgroundColor = .systemOrange
        doneAction.backgroundColor = .systemBlue
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction, doneAction])
        return configuration
    }
}

