# Prevent First Responder Orphans

I recently had an interesting bug report / feature request. When editing the title to a trip you can can easily scroll away from it and forget what the keyboard is representing.

Our App's main view is a table view, where some of the cells are editable, and others are just static content (a day note vs. a day Heading)

A good solution to this issue is to end editing when the thing you are currently editing (the first responder) goes off screen. You could keep a reference to the currently editing cell, then resign first responder when that cell goes off screen, but this feels like managing state.

OK but we do want to end the cell editing when it goes off screen, but we don't want to have to keep track of which cell is editing. We know the editing cell is currently the first responder, so how do we get a reference to the first responder? Through some magic, that's how.

## Finding The First Responder

`UIApplication` has a function for sending "Target -> Action" messages. We are going to use that. Checking the docs for `UIApplication.sendAction(_:to:from:forEvent)` shows that if the target is `nil` this action is delivered to the `firstResponder`.

So we will send the first responder a message: 

```swift
UIApplication.sharedApplication().sendAction("message:", to: nil, from: nil, forEvent: nil)
```

OK cool we can send `message:` to the first responder, but what should our function do. We need the first responder to receive this message and to do something? probably return self so we can get a reference to it. 

We also want this to be callable from anywhere so we will make it a class function on `UIResponder`. It should also return us a responder so that we can end editing on that responder.

```swift

extension UIResponder  {
    private static weak var currentResponder: UIResponder? = nil

    class func requestFirstResponder() -> UIResponder? {
        currentResponder = nil
        UIApplication.sharedApplication().sendAction("getFirstResponder:", to: nil, from: nil, forEvent: nil)
        return currentResponder
    }

    func getFirstResponder() {
        UIResponder.currentResponder = self
    }
}
```

OK so digging through the code above: `requestFirstResponder()` needs to return an optional because you don't always have a first responder. We need to use `sendAction` to the `UIApplication` so that our message gets passed on to the first responder. Our `saveSelf()` function is pretty much as easy as could be. To tie it all up, we need to set the previous responder to nil, before fetching a new first responder, (in case it's nil) then return the found first responder. Finally we will make our `currrentResponder` storage weak since, someone else is certainly holding a reference to it already, the super view, the view controller ... we don't need it to stick around, plus it's optional so we will handle it with care anyway. 

## When to dismiss

Now that we can get a reference to the first responder at will, we can focus on the second problem, "When should we dismiss the keyboard?".

We have a couple of options:

* When the user scrolls
* When the user scrolls fast
* When the text box exits the screen

I think the last one, "When the text field goes off screen", is the best. How do we know when it goes off screen? 

The `UITextField` is in a scroll view. So we can just compare the frame of the text field with the scroll view's content offset to see if it is still on screen. Since the table view is a subclass of scroll view we can set ourselves as the `scrollViewDelete` and use those call backs to determine when to dismiss our first responder.
`scrollViewDidScroll` looks promising but gets called on every frame and may have performance implications. What about
```scrollViewDidEndDragging:withDecelerate:```
is pretty promising but gets called when the users finger lifts after scrolling, how do we know where the screen will stop after it decelerates. The method we really want to use is 
```scrollViewWillEndDragging(scrollView:withVelocity:targetContentOffset:)```
This method is amazing. It tells you where the scroll view will be when the animation finishes. This is the one we will use.

Here is the completed method.
```swift
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
```
Line 1 gets the final resting offset off the scroll view, we need to reach through the `memory` because the value is in an `UnsafeMutablePointer`. Line 2 was a bit confusing to me even after the first time I had written it. Remember bounds is always in the view's own coordinate system, so origin is almost always (0,0), and the frame has the origin in the superview's coordinates system, But what we really want is to have the frame of the first responder in the scroll Views coordinate system. We can get this with the `convertRect` method. This will let us know where our first responder sits inside of the scroll view, then we can figure out if it is still on screen. 

Line 3 is where we finally put this new amazing offset to good use. What part of the scroll view's content will be visible when the scroll animation ends. We just build a CGRect using the scroll view's current parts, but having the new offset.
Finally on Line 4 we check if the scroll view's visible region contains our first responder. 

## Closing

I put a small sample project on github.com/regnerjr/DismissKeyboardByScrolling. Thanks.
