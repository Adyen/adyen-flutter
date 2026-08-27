protocol DropInWindowManagerDelegate: AnyObject {
    /// Called when the Drop-in window was torn down without a dismissal having been requested, for example when the
    /// hosting scene disconnects.
    func dropInWindowDidDismissUnexpectedly()
}
