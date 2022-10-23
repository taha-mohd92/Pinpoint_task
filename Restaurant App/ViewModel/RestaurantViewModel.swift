//
//  RestaurantViewModel.swift
//  Restaurant App
//
//  Created by Mohd Taha on 21/10/2022.
//

import Foundation

enum PaymentMethodType: Double {
    case cash = 0.0         // 0%
    case creditCard = 0.012   // 1.2%
    
    func getValue() -> Double {
        return 1+self.rawValue
    }
}

enum DiscountType {
    case percentage
    case dollar
}

enum SplitType {
    case noSplit
    case splitEqually
    case splitIndividually
}

struct FoodItem {
    var id: Int
    var name: String
    var price: Double
}

struct OrderedItem {
    var foodItem: FoodItem
    var quantity: Int
    var personId: Int
    
    func totalSum() -> Double {
        return foodItem.price*Double(quantity)
    }
    
    func totalSum(paymentMethod: PaymentMethodType = .cash) -> Double {
        let individualSurcharge = totalSum()*paymentMethod.rawValue/100
        return totalSum()+individualSurcharge
    }
}

struct GroupDetails {
    var groupName: String
    var pax: Int = 1
    var tab: Double = Double.greatestFiniteMagnitude
    var discount: Double = 0.0
    var discountType: DiscountType = .percentage
    var paymentMethod: PaymentMethodType = .cash
    var split: SplitType = .noSplit
}

struct Invoice {
    var title: String
    var data: String
}

protocol ViewModelDelegate {
    func reloadView()
}

class RestaurantViewModel {
    var delegate: ViewModelDelegate?
    
    var foodList: [FoodItem] = [
        FoodItem(id: 1, name: "Big Brekkie", price: 16.0),
        FoodItem(id: 2, name: "Bruschetta", price: 8.0),
        FoodItem(id: 3, name: "Poached Eggs", price: 12.0),
        FoodItem(id: 4, name: "Coffee", price: 5.0),
        FoodItem(id: 5, name: "Tea", price: 3.0),
        FoodItem(id: 6, name: "Soda", price: 4.0),
        FoodItem(id: 7, name: "Garden Salad", price: 10.0)
    ]
    
    var orderedItems: [OrderedItem] = []
    var groupDetail: GroupDetails = GroupDetails(groupName: "Group 1")
    
    var isTabValid: Bool {
        return !(totalItemValueWithDiscount > groupDetail.tab)
    }
    
    var totalItemAmount: Double {
        var totalItemValue = 0.0
        orderedItems.forEach ({ totalItemValue += $0.totalSum() })
        return totalItemValue
    }
    
    var discount: Double {
        var discount = 0.0
        if groupDetail.discountType == .percentage {
            discount = (totalItemAmount*groupDetail.discount/100)
        } else {
            discount = groupDetail.discount
        }
        return discount
    }
    
    var totalItemValueWithDiscount: Double {
        return totalItemAmount - discount
    }
    
    var surcharge: Double {
        return totalItemValueWithDiscount*groupDetail.paymentMethod.rawValue
    }
    
    var finalBill: Double {
        return (totalItemValueWithDiscount + surcharge)
    }
    
    var finalSplitBill: Double {
        return (totalItemValueWithDiscount + surcharge)/Double(groupDetail.pax)
    }
    
    func updateViewModel(data: Any, tag: Int) {
        switch tag {
        case 1: groupDetail.groupName = (data as? String) ?? ""
        case 2: groupDetail.pax = (data as? Int) ?? 0
        case 3: groupDetail.tab = (data as? Double) ?? 0.0
        case 4: groupDetail.discount = (data as? Double) ?? 0.0
        case 5: groupDetail.discountType = ((data as? Bool) ?? false) ? .dollar : .percentage
        case 6: groupDetail.paymentMethod = ((data as? Bool) ?? false) ? .creditCard : .cash
        case 7: groupDetail.split = (data as? SplitType) ?? .noSplit
        default: break
        }
    }
    
    func addToOrderedList(item: FoodItem, forPersonId: Int) {
        if !orderedItems.contains(where: { ($0.foodItem.id == item.id && $0.personId == forPersonId ) }) {
            orderedItems.append(OrderedItem(foodItem: item, quantity: 1, personId: forPersonId))
        } else {
            orderedItems = orderedItems.map({ orderedItem in
                if orderedItem.foodItem.id == item.id && orderedItem.personId == forPersonId {
                    var updatedItem = orderedItem
                    updatedItem.quantity += 1
                    return updatedItem
                }
                return orderedItem
            })
        }
        delegate?.reloadView()
    }
    
    func removeItem(index: Int) {
        orderedItems.remove(at: index)
        delegate?.reloadView()
    }
    
    func calculateTotal() -> [Invoice] {
        var invoice: [Invoice] = []
        invoice.append(Invoice(title: "Group Name", data: groupDetail.groupName))
        invoice.append(Invoice(title: "Tax", data: "0.0$"))
        invoice.append(Invoice(title: "Total w/o Discount", data: "\(totalItemAmount.round())$"))
        invoice.append(Invoice(title: "Discount", data: "\(discount.round())$"))
        invoice.append(Invoice(title: "Total with Discount", data: "\(totalItemValueWithDiscount.round())$"))
        
        switch groupDetail.split {
        case .noSplit:
            invoice.append(Invoice(title: "Surcharge", data: "\(surcharge.round())$"))
            invoice.append(Invoice(title: "Total after Surcharge", data: "\(finalBill.round())$"))
            
        case .splitEqually:
            invoice.append(Invoice(title: "Surcharge", data: "\(surcharge.round())$"))
            invoice.append(Invoice(title: "Total", data: "\(finalBill.round())$"))
            invoice.append(Invoice(title: "Per head", data: "\(finalSplitBill.round())$"))
            
        case .splitIndividually:
            for personId in 1...groupDetail.pax {
                var individualTotal = 0.0
                orderedItems.forEach { orderedItem in
                    if orderedItem.personId == personId {
                        individualTotal += orderedItem.totalSum()
                    }
                }
                var individualdiscount = 0.0
                if groupDetail.discountType == .percentage {
                    individualdiscount = (individualTotal*groupDetail.discount/100)
                } else {
                    individualdiscount = individualTotal/totalItemAmount*groupDetail.discount
                }
                var individualTotalWithDiscount = individualTotal - individualdiscount

                invoice.append(Invoice(title: "Person \(personId)", data: "\(individualTotalWithDiscount.round())$"))
                invoice.append(Invoice(title: "     Total", data: "\(individualTotal.round())$"))
                invoice.append(Invoice(title: "     Discount", data: "\(individualdiscount.round())$"))
                invoice.append(Invoice(title: "     Total after Discount", data: "\(individualTotalWithDiscount.round())$"))
                individualTotalWithDiscount = individualTotalWithDiscount*groupDetail.paymentMethod.getValue()
                invoice.append(Invoice(title: "     Total With Surcharge", data: "\(individualTotalWithDiscount.round())$"))
            }
        }
        return invoice
    }
}

extension Double {
    func round(radix: Int = 10, places: Int = 2) -> Double {
        let factor = pow(Double(radix), Double(places))
        return (self * factor).rounded() / factor
    }
}
