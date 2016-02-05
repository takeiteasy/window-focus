import Cocoa

let options        = CGWindowListOption(arrayLiteral: CGWindowListOption.ExcludeDesktopElements, CGWindowListOption.OptionOnScreenOnly)
let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
let infoList       = windowListInfo as NSArray? as? [[String: AnyObject]]
for dict in infoList as [[String: AnyObject]]! {
  print(dict)
}
