import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

	@IBOutlet weak var tableView: UITableView!

	lazy var data = Array(0..<200)

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return data.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(String(CustomCell), forIndexPath: indexPath) as! CustomCell
		cell.label.text = String(data[indexPath.row])
		return cell
	}
}

class CustomCell: UITableViewCell {
	@IBOutlet var label: UILabel!
	@IBOutlet var textField: UITextField!
}