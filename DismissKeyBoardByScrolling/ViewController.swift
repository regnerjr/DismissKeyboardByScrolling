import UIKit

class ViewController: UITableViewController {

	lazy var data = Array(0..<50)

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return data.count
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(String(CustomCell), forIndexPath: indexPath) as! CustomCell
		cell.label.text = String(data[indexPath.row])
		return cell
	}

	override func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
		// Check if we have a first responder
		guard let firstResponder = UIResponder.findFirstResponder() as? UIView else { return }
		// 1
		let offset = targetContentOffset.memory.y // Get the final Y offset
		// 2
		let rectInScrollView = scrollView.convertRect(firstResponder.bounds, fromView: firstResponder)
		//3
		let scrollViewFutureBounds = CGRect(origin: CGPoint(x: scrollView.contentOffset.x, y: offset ), size: scrollView.bounds.size)
		// 4
		if !scrollViewFutureBounds.contains(rectInScrollView) {
			firstResponder.endEditing(true)
		}
	}
}

class CustomCell: UITableViewCell {
	@IBOutlet var label: UILabel!
	@IBOutlet var textField: UITextField!
}

extension UIResponder {
	private static var responder: UIResponder? = nil

	class func findFirstResponder() -> UIResponder? {
		responder = nil
		UIApplication.sharedApplication().sendAction("getFirstResponder", to: nil, from: nil, forEvent: nil)
		return responder
	}

	func getFirstResponder() {
		UIResponder.responder = self
	}
}
