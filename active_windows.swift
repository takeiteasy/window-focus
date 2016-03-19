import Cocoa

for dict in ((CGWindowListCopyWindowInfo(CGWindowListOption(arrayLiteral: CGWindowListOption.ExcludeDesktopElements, CGWindowListOption.OptionOnScreenOnly), CGWindowID(0))) as NSArray? as? [[String: AnyObject]]) as [[String: AnyObject]]! {
  print(dict)
}
