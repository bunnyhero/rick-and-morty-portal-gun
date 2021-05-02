//
//  LocationPickerViewController.swift
//  RKTest
//
//  Created by bunnyhero on 2021-05-03.
//

import UIKit

class LocationPickerViewController: UIViewController {
    weak var delegate: LocationPickerViewControllerDelegate?
    
    var currentLocation: Location? { didSet { updateCurrent() } }
    var locations: [Location] = [] { didSet { reloadPicker() } }
    
    @IBOutlet weak var pickerView: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func updateCurrent() {
        if let row = locations.firstIndex(where: { $0.name == currentLocation?.name }) {
            pickerView.selectRow(row, inComponent: 0, animated: false)
        }
    }

    func reloadPicker() {
        pickerView.reloadAllComponents()
    }
    
    @IBAction func didTapSelect(_ sender: Any) {
        let row = pickerView.selectedRow(inComponent: 0)
        let selectedLocation = row < locations.count ? locations[row] : nil
        delegate?.locationPicker(self, didSelectLocation: selectedLocation)
    }
}

extension LocationPickerViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return locations.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return locations[row].name
    }
}


protocol LocationPickerViewControllerDelegate: AnyObject {
    func locationPicker( _ viewController: LocationPickerViewController, didSelectLocation location: Location?)
}
