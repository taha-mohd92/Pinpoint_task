//
//  ViewController.swift
//  Restaurant App
//
//  Created by Mohd Taha on 20/10/2022.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var groupNameTextField: UITextField!
    @IBOutlet weak var noOfPeopleTextField: UITextField!
    @IBOutlet weak var addItemsButton: UIButton!
    @IBOutlet weak var editItemsButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tabTextField: UITextField!
    @IBOutlet weak var discountTextField: UITextField!
    @IBOutlet weak var discountSwitch: UISwitch!
    @IBOutlet weak var paymentMethodSwitch: UISwitch!
    @IBOutlet weak var splitButton: UIButton!
    @IBOutlet weak var showInvoiceButton: UIButton!
    @IBOutlet weak var resultStackView: UIStackView!
    
    
    var viewModel: RestaurantViewModel = RestaurantViewModel()
    var alert: UIAlertController?
    var personId: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _setupView()
    }
    
    private func _setupView() {
        tableView.register(CustomCell.self, forCellReuseIdentifier: "BasicCell")
        tableView.delegate = self
        tableView.dataSource = self
        
        viewModel.delegate = self
        noOfPeopleTextField.delegate = self
        tabTextField.delegate = self
        groupNameTextField.delegate = self
        discountTextField.delegate = self
        tabTextField.delegate = self

        discountSwitch.isOn = false
        paymentMethodSwitch.isOn = false
        
        splitButton.isEnabled = true
        showInvoiceButton.isEnabled = false
        editItemsButton.isEnabled = false
        addItemsButton.isEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
         tableView.frame = CGRect(x: tableView.frame.origin.x, y: tableView.frame.origin.y, width: tableView.frame.size.width, height: tableView.contentSize.height)
         tableView.reloadData()
    }

    @IBAction func addItemButtonAction(_ sender: Any) {
        tableView.isEditing = false
        addItemTapped()
    }
    
    @IBAction func editItemButtonAction(_ sender: Any) {
        tableView.isEditing = true
        tableView.reloadData()
    }
    
    @IBAction func showInvoiceButtonAction(_ sender: Any) {
        viewModel.groupDetail.discountType = discountSwitch.isOn ? DiscountType.dollar : DiscountType.percentage
        viewModel.groupDetail.paymentMethod = paymentMethodSwitch.isOn ? PaymentMethodType.creditCard : PaymentMethodType.cash

        for view in resultStackView.arrangedSubviews{
            resultStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        let invoice = viewModel.calculateTotal()
        invoice.forEach { resultItem in
            let label = UILabel()
            label.text = "  \(resultItem.title) : \(resultItem.data)    "
            resultStackView.addArrangedSubview(label)
        }
        print(invoice)
    }
    
    func enableInvoiceButton() {
        let hasGroupName = groupNameTextField.text?.count ?? 0 > 0
        
        var hasPax = false
        if let paxText = noOfPeopleTextField.text, let pax = Int(paxText), pax > 0 {
            hasPax = true
        }
        showInvoiceButton.isEnabled = hasGroupName && hasPax && viewModel.isTabValid
    }
    
    @objc func addItemTapped() {
        alert = UIAlertController(title: "Food Items", message: "Please select an item", preferredStyle: .alert)
        viewModel.foodList.forEach { foodItem in
            let foodItemAction = UIAlertAction(title: "\(foodItem.name)(\(foodItem.price)$)", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.addToOrderedList(item: foodItem, forPersonId: self.personId)
            })
            foodItemAction.isEnabled = false
            alert?.addAction(foodItemAction)
        }
        alert?.addTextField { textField in
            textField.tag = 10
            textField.placeholder = "Enter Person id"
            textField.keyboardType = .numberPad
            textField.delegate = self
        }
        alert?.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert!, animated: true, completion: nil)
    }
    
    
    @IBAction func splitButtonAction(_ sender: Any) {
        let splitTypeAlert = UIAlertController(title: "Split Selection Items", message: "Please select an item", preferredStyle: .alert)
        
        splitTypeAlert.addAction(UIAlertAction(title: "No Split", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.splitButton.setTitle("No Split", for: .normal)
            self.viewModel.groupDetail.split = .noSplit
        }))
        
        splitTypeAlert.addAction(UIAlertAction(title: "Split Equally", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.splitButton.setTitle("Split Equally", for: .normal)
            self.viewModel.groupDetail.split = .splitEqually
        }))
        
        splitTypeAlert.addAction(UIAlertAction(title: "Split Individually", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.splitButton.setTitle("Split Individually", for: .normal)
            self.viewModel.groupDetail.split = .splitIndividually
        }))
        
        splitTypeAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(splitTypeAlert, animated: true, completion: nil)
    }
}

extension ViewController: ViewModelDelegate {
    func reloadView() {
        enableInvoiceButton()
        editItemsButton.isEnabled = !viewModel.orderedItems.isEmpty
        tableView.reloadData()
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        switch textField.tag {
        case 1:
            if let text = textField.text, text.count > 0 {
                viewModel.groupDetail.groupName = text
            }
            reloadView()
            
        case 2:
            if let text = textField.text, let pax = Int(text), pax > 0 {
                viewModel.groupDetail.pax = pax
                addItemsButton.isEnabled = true
                return
            }
            addItemsButton.isEnabled = false
            
        case 3:
            if let text = textField.text, let tab = Double(text) {
                viewModel.groupDetail.tab = tab
            }
            reloadView()
            
        case 4:
            viewModel.groupDetail.discount = Double(textField.text ?? "0") ?? 0.0
            reloadView()
            
        case 10:
            // tag = 10 for pax text field in Alert
            if let text = textField.text, let personNumber = Int(text) {
                if personNumber <= viewModel.groupDetail.pax {
                    personId = personNumber
                    alert?.message = "Please select an item"
                    alert?.actions.forEach({ item in
                        if item.style != .cancel {
                            item.isEnabled = text.count > 0
                        }
                    })
                } else {
                    alert?.message = "Please Enter Person Id in range of 1 to \(viewModel.groupDetail.pax)"
                }
            }
        default: break
        }
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.orderedItems.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell") as? CustomCell else { return UITableViewCell() }
        let orderedItem = viewModel.orderedItems[indexPath.row]
        cell.textLabel?.text = "\(orderedItem.foodItem.name) (\(orderedItem.foodItem.price)$)"
        cell.detailTextLabel?.text = "Quantity: \(orderedItem.quantity)   Total: \(orderedItem.totalSum())$     Person Id: \(orderedItem.personId)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCell.EditingStyle.delete) {
            viewModel.removeItem(index: indexPath.row)
        }
    }
}

